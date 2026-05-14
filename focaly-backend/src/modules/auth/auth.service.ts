import { randomUUID } from 'crypto';

import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Request } from 'express';
import type Redis from 'ioredis';
import { Model } from 'mongoose';

import { CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { MAILER, Mailer } from '../../infrastructure/mailer/mailer.module';
import { REDIS_CLIENT } from '../../infrastructure/redis/redis.tokens';
import { UsersRepository } from '../users/users.repository';

import { AuthSessionsRepository } from './auth-sessions.repository';
import {
  ForgotPasswordDto,
  GoogleLoginDto,
  LoginDto,
  RefreshDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyEmailDto,
} from './dto';
import { GoogleAuthService } from './google-auth.service';
import { JwtService, RefreshTokenClaims, TokenPairResult } from './jwt.service';
import { PasswordService } from './password.service';
import { AuditLog, AuditLogDocument } from './schemas/audit-log.schema';
import { buildVerificationEmail } from './templates/email-verification.template';
import { buildPasswordResetEmail } from './templates/password-reset.template';

export interface RequestMeta {
  ip?: string | null;
  userAgent?: string | null;
  requestId?: string | null;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly authSessionsRepository: AuthSessionsRepository,
    private readonly jwtService: JwtService,
    private readonly passwordService: PasswordService,
    private readonly googleAuthService: GoogleAuthService,
    @Inject(MAILER) private readonly mailer: Mailer,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @InjectModel(AuditLog.name) private readonly auditLogModel: Model<AuditLogDocument>,
  ) {}

  async register(
    dto: RegisterDto,
    meta: RequestMeta,
    deviceId?: string,
  ): Promise<{ user: unknown; tokens: TokenPairResult }> {
    const existingUser = await this.usersRepository.findActiveByEmail(dto.email);
    if (existingUser) {
      throw new ConflictException({
        code: ERROR_CODES.CONFLICT,
        message: 'A user with that email already exists.',
      });
    }

    const passwordHash = await this.passwordService.hash(dto.password);
    const user = await this.usersRepository.create({
      email: dto.email,
      passwordHash,
      name: dto.name,
      emailVerified: false,
    });

    const userId = getDocumentId(user);
    await this.sendEmailToken(userId, user.email, 'verify-email');
    const tokens = await this.issueSessionTokens(
      {
        id: userId,
        email: user.email,
        role: user.role,
        plan: user.plan,
        premiumUntil: user.premiumUntil,
        emailVerified: user.emailVerified,
      },
      {
        deviceId: deviceId ?? `signup-${randomUUID()}`,
        fcmToken: null,
        ip: meta.ip ?? null,
        userAgent: meta.userAgent ?? null,
      },
    );

    return { user, tokens };
  }

  async login(
    dto: LoginDto,
    meta: RequestMeta,
  ): Promise<{ user: unknown; tokens: TokenPairResult }> {
    const user = await this.usersRepository.findActiveByEmail(dto.email);
    if (!user?.passwordHash) {
      throw this.unauthorized('Email or password is invalid.');
    }

    const valid = await this.passwordService.verify(user.passwordHash, dto.password);
    if (!valid) {
      throw this.unauthorized('Email or password is invalid.');
    }

    const userId = getDocumentId(user);
    const tokens = await this.issueSessionTokens(
      {
        id: userId,
        email: user.email,
        role: user.role,
        plan: user.plan,
        premiumUntil: user.premiumUntil,
        emailVerified: user.emailVerified,
      },
      {
        deviceId: dto.deviceId,
        fcmToken: dto.fcmToken ?? null,
        ip: meta.ip ?? null,
        userAgent: meta.userAgent ?? null,
      },
    );

    return { user, tokens };
  }

  async googleLogin(
    dto: GoogleLoginDto,
    meta: RequestMeta,
  ): Promise<{ user: unknown; tokens: TokenPairResult }> {
    const profile = await this.googleAuthService.verifyIdToken(dto.idToken);
    let user = await this.usersRepository.findActiveByGoogleId(profile.googleId);

    if (!user && profile.emailVerified) {
      user = await this.usersRepository.findActiveByEmail(profile.email);
      if (user) {
        user = await this.usersRepository.updateById(getDocumentId(user), {
          $set: {
            googleId: profile.googleId,
            emailVerified: true,
            avatarUrl: user.avatarUrl ?? profile.picture ?? null,
          },
        });
      }
    }

    if (!user) {
      user = await this.usersRepository.create({
        email: profile.email,
        passwordHash: null,
        name: profile.name,
        googleId: profile.googleId,
        avatarUrl: profile.picture ?? null,
        emailVerified: profile.emailVerified,
      });
    }

    const userId = getDocumentId(user);
    const tokens = await this.issueSessionTokens(
      {
        id: userId,
        email: user.email,
        role: user.role,
        plan: user.plan,
        premiumUntil: user.premiumUntil,
        emailVerified: user.emailVerified,
      },
      {
        deviceId: dto.deviceId,
        fcmToken: dto.fcmToken ?? null,
        ip: meta.ip ?? null,
        userAgent: meta.userAgent ?? null,
      },
    );

    return { user, tokens };
  }

  async refresh(
    dto: RefreshDto,
    claims: RefreshTokenClaims,
    meta: RequestMeta,
  ): Promise<TokenPairResult> {
    if (claims.deviceId !== dto.deviceId) {
      throw this.unauthorized('Refresh token does not match this device.');
    }

    const session = await this.authSessionsRepository.findActiveById(claims.sessionId);
    if (!session || session.userId.toString() !== claims.sub || session.family !== claims.family) {
      throw this.unauthorized('Refresh token is invalid or expired.');
    }

    const isCurrentToken = await this.passwordService.verify(
      session.refreshTokenHash,
      dto.refreshToken,
    );
    if (!isCurrentToken) {
      const consumedKey = this.getConsumedRefreshKey(claims.family, claims.jti);
      const wasConsumed = await this.redis.get(consumedKey);
      if (wasConsumed) {
        await this.authSessionsRepository.revokeFamily(claims.sub, claims.family);
        await this.recordRefreshReuse(claims, meta);
      }
      throw this.unauthorized('Refresh token is invalid or expired.');
    }

    await this.redis.set(
      this.getConsumedRefreshKey(claims.family, claims.jti),
      '1',
      'EX',
      this.jwtService.getRefreshTtlSeconds(),
    );

    const user = await this.usersRepository.findActiveById(claims.sub);
    if (!user) {
      throw this.unauthorized('User no longer exists.');
    }

    const tokens = this.jwtService.signTokenPair(
      {
        id: getDocumentId(user),
        email: user.email,
        role: user.role,
        plan: user.plan,
        premiumUntil: user.premiumUntil,
        emailVerified: user.emailVerified,
      },
      getDocumentId(session),
      dto.deviceId,
      claims.family,
    );
    const refreshTokenHash = await this.passwordService.hash(tokens.refreshToken);
    await this.authSessionsRepository.updateRefreshToken(
      getDocumentId(session),
      refreshTokenHash,
      this.buildSessionExpiry(tokens.refreshExpiresIn),
    );

    await this.usersRepository.updateOne(
      { _id: getDocumentId(user) },
      { $set: { lastActiveAt: new Date() } },
    );
    return tokens;
  }

  async logout(user: CurrentUserPayload): Promise<void> {
    await this.authSessionsRepository.revokeById(user.id, user.sessionId);
  }

  async logoutAll(user: CurrentUserPayload): Promise<void> {
    await this.authSessionsRepository.revokeAllByUserId(user.id);
  }

  async forgotPassword(dto: ForgotPasswordDto): Promise<void> {
    const user = await this.usersRepository.findActiveByEmail(dto.email);
    if (!user) {
      return;
    }

    const token = await this.sendEmailToken(getDocumentId(user), user.email, 'reset-password');
    await this.mailer.send(buildPasswordResetEmail(user.email, token));
  }

  async resetPassword(dto: ResetPasswordDto): Promise<void> {
    const payload = this.jwtService.verifyEmailToken(dto.token);
    if (payload.purpose !== 'reset-password') {
      throw this.unauthorized('Token is invalid or expired.');
    }

    const redisKey = this.getEmailTokenKey(payload.purpose, payload.jti);
    const exists = await this.redis.get(redisKey);
    if (!exists) {
      throw this.unauthorized('Token is invalid or expired.');
    }

    await this.redis.del(redisKey);
    const passwordHash = await this.passwordService.hash(dto.newPassword);
    await this.usersRepository.updateOne(
      { _id: payload.sub, isDeleted: false },
      { $set: { passwordHash, lastActiveAt: new Date() } },
    );
    await this.authSessionsRepository.revokeAllByUserId(payload.sub);
  }

  async verifyEmail(dto: VerifyEmailDto): Promise<void> {
    const payload = this.jwtService.verifyEmailToken(dto.token);
    if (payload.purpose !== 'verify-email') {
      throw this.unauthorized('Token is invalid or expired.');
    }

    const redisKey = this.getEmailTokenKey(payload.purpose, payload.jti);
    const exists = await this.redis.get(redisKey);
    if (!exists) {
      throw this.unauthorized('Token is invalid or expired.');
    }

    await this.redis.del(redisKey);
    await this.usersRepository.updateOne(
      { _id: payload.sub, isDeleted: false },
      { $set: { emailVerified: true, lastActiveAt: new Date() } },
    );
  }

  async listSessions(user: CurrentUserPayload): Promise<Array<Record<string, unknown>>> {
    const sessions = await this.authSessionsRepository.findActiveByUserId(user.id);
    return sessions.map((session) => ({
      ...session.toObject(),
      current: getDocumentId(session) === user.sessionId,
    }));
  }

  async revokeSession(user: CurrentUserPayload, sessionId: string): Promise<void> {
    const session = await this.authSessionsRepository.revokeById(user.id, sessionId);
    if (!session) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Session was not found.',
      });
    }
  }

  private async issueSessionTokens(
    user: {
      id: string;
      email: string;
      role: 'user' | 'admin';
      plan: 'free' | 'premium';
      premiumUntil?: Date | null;
      emailVerified: boolean;
    },
    sessionInput: {
      deviceId: string;
      fcmToken?: string | null;
      ip?: string | null;
      userAgent?: string | null;
    },
  ): Promise<TokenPairResult> {
    const family = randomUUID();
    const placeholderHash = await this.passwordService.hash(`pending-${family}`);
    const expiresAt = this.buildSessionExpiry(this.jwtService.getRefreshTtlSeconds());
    const session = await this.authSessionsRepository.upsertByUserDevice({
      userId: user.id,
      deviceId: sessionInput.deviceId,
      refreshTokenHash: placeholderHash,
      family,
      expiresAt,
      userAgent: sessionInput.userAgent ?? null,
      ip: sessionInput.ip ?? null,
      fcmToken: sessionInput.fcmToken ?? null,
    });

    const sessionId = getDocumentId(session);
    const tokens = this.jwtService.signTokenPair(user, sessionId, sessionInput.deviceId, family);
    const refreshTokenHash = await this.passwordService.hash(tokens.refreshToken);
    await this.authSessionsRepository.updateRefreshToken(sessionId, refreshTokenHash, expiresAt);
    await this.usersRepository.updateOne({ _id: user.id }, { $set: { lastActiveAt: new Date() } });
    return tokens;
  }

  private async sendEmailToken(
    userId: string,
    email: string,
    purpose: 'verify-email' | 'reset-password',
  ): Promise<string> {
    const { token, jti, expiresIn } = this.jwtService.signEmailToken({
      sub: userId,
      email,
      purpose,
    });
    await this.redis.set(this.getEmailTokenKey(purpose, jti), userId, 'EX', expiresIn);
    if (purpose === 'verify-email') {
      await this.mailer.send(buildVerificationEmail(email, token));
    }
    return token;
  }

  private buildSessionExpiry(ttlSeconds: number): Date {
    return new Date(Date.now() + ttlSeconds * 1000);
  }

  private getConsumedRefreshKey(family: string, jti: string): string {
    return `auth:refresh:consumed:${family}:${jti}`;
  }

  private getEmailTokenKey(purpose: string, jti: string): string {
    return `auth:email:${purpose}:${jti}`;
  }

  private unauthorized(message: string): UnauthorizedException {
    return new UnauthorizedException({
      code: ERROR_CODES.UNAUTHORIZED,
      message,
    });
  }

  private async recordRefreshReuse(claims: RefreshTokenClaims, meta: RequestMeta): Promise<void> {
    await this.auditLogModel.create({
      userId: claims.sub,
      actor: 'user',
      eventType: 'auth.refresh.reuse',
      requestId: meta.requestId ?? null,
      ip: meta.ip ?? null,
      userAgent: meta.userAgent ?? null,
      data: { sessionId: claims.sessionId, family: claims.family, jti: claims.jti },
    });
  }
}

export function getRequestMeta(req: Request): RequestMeta {
  return {
    ip: req.ip,
    userAgent: req.get('user-agent') ?? null,
    requestId: (req as { id?: string }).id ?? null,
  };
}

function getDocumentId(doc: { _id?: unknown; id?: string }): string {
  if (typeof doc.id === 'string' && doc.id.length > 0) {
    return doc.id;
  }

  return String(doc._id);
}
