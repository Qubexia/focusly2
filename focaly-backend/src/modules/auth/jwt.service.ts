import { randomUUID } from 'crypto';

import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService as NestJwtService } from '@nestjs/jwt';

import { ACCESS_TOKEN_TYPE, REFRESH_TOKEN_TYPE } from '../../common/constants/auth.constants';
import { ERROR_CODES } from '../../common/dto/api-response';

export interface JwtUserClaimsInput {
  id: string;
  email: string;
  role: 'user' | 'admin';
  plan: 'free' | 'premium';
  premiumUntil?: Date | null;
  emailVerified: boolean;
}

export interface AccessTokenClaims {
  sub: string;
  email: string;
  role: 'user' | 'admin';
  plan: 'free' | 'premium';
  premiumUntil?: string | null;
  emailVerified: boolean;
  sessionId: string;
  type: typeof ACCESS_TOKEN_TYPE;
}

export interface RefreshTokenClaims {
  sub: string;
  sessionId: string;
  deviceId: string;
  family: string;
  jti: string;
  type: typeof REFRESH_TOKEN_TYPE;
}

export interface TokenPairResult {
  accessToken: string;
  refreshToken: string;
  accessExpiresIn: number;
  refreshExpiresIn: number;
  refreshJti: string;
}

export interface EmailTokenClaims {
  sub: string;
  email: string;
  jti: string;
  purpose: 'verify-email' | 'reset-password';
}

export function derivePlanForClaims(user: JwtUserClaimsInput): 'free' | 'premium' {
  if (user.plan !== 'premium') {
    return 'free';
  }

  if (!user.premiumUntil) {
    return 'premium';
  }

  return new Date(user.premiumUntil) > new Date() ? 'premium' : 'free';
}

@Injectable()
export class JwtService {
  private readonly accessJwt: NestJwtService;
  private readonly refreshJwt: NestJwtService;
  private readonly emailSecret: string;
  private readonly accessTtlSeconds: number;
  private readonly refreshTtlSeconds: number;

  constructor(private readonly configService: ConfigService) {
    const privateKey = this.configService.getOrThrow<string>('jwt.privateKey');
    const publicKey = this.configService.getOrThrow<string>('jwt.publicKey');

    this.accessTtlSeconds = this.configService.get<number>('jwt.accessTtlSeconds') ?? 900;
    this.refreshTtlSeconds = this.configService.get<number>('jwt.refreshTtlSeconds') ?? 2_592_000;
    this.emailSecret = this.configService.getOrThrow<string>('jwt.emailTokenSecret');

    this.accessJwt = new NestJwtService({
      privateKey,
      publicKey,
      signOptions: { algorithm: 'RS256', expiresIn: this.accessTtlSeconds },
      verifyOptions: { algorithms: ['RS256'] },
    });
    this.refreshJwt = new NestJwtService({
      privateKey,
      publicKey,
      signOptions: { algorithm: 'RS256', expiresIn: this.refreshTtlSeconds },
      verifyOptions: { algorithms: ['RS256'] },
    });
  }

  signTokenPair(
    user: JwtUserClaimsInput,
    sessionId: string,
    deviceId: string,
    family: string,
  ): TokenPairResult {
    const refreshJti = randomUUID();
    const accessPayload: AccessTokenClaims = {
      sub: user.id,
      email: user.email,
      role: user.role,
      plan: derivePlanForClaims(user),
      premiumUntil: user.premiumUntil ? new Date(user.premiumUntil).toISOString() : null,
      emailVerified: user.emailVerified,
      sessionId,
      type: ACCESS_TOKEN_TYPE,
    };
    const refreshPayload: RefreshTokenClaims = {
      sub: user.id,
      sessionId,
      deviceId,
      family,
      jti: refreshJti,
      type: REFRESH_TOKEN_TYPE,
    };

    return {
      accessToken: this.accessJwt.sign(accessPayload),
      refreshToken: this.refreshJwt.sign(refreshPayload),
      accessExpiresIn: this.accessTtlSeconds,
      refreshExpiresIn: this.refreshTtlSeconds,
      refreshJti,
    };
  }

  signEmailToken(
    payload: Omit<EmailTokenClaims, 'jti'>,
    expiresInSeconds = 3_600,
  ): { token: string; jti: string; expiresIn: number } {
    const jti = randomUUID();
    const token = new NestJwtService({
      secret: this.emailSecret,
      signOptions: { expiresIn: expiresInSeconds },
    }).sign({ ...payload, jti });

    return { token, jti, expiresIn: expiresInSeconds };
  }

  verifyAccessToken(token: string): AccessTokenClaims {
    return this.verifyOrThrow<AccessTokenClaims>(token, ACCESS_TOKEN_TYPE, this.accessJwt);
  }

  verifyRefreshToken(token: string): RefreshTokenClaims {
    return this.verifyOrThrow<RefreshTokenClaims>(token, REFRESH_TOKEN_TYPE, this.refreshJwt);
  }

  verifyEmailToken(token: string): EmailTokenClaims {
    try {
      return new NestJwtService({ secret: this.emailSecret }).verify<EmailTokenClaims>(token);
    } catch {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Token is invalid or expired.',
      });
    }
  }

  getRefreshTtlSeconds(): number {
    return this.refreshTtlSeconds;
  }

  private verifyOrThrow<T extends { type: string }>(
    token: string,
    expectedType: string,
    jwt: NestJwtService,
  ): T {
    try {
      const payload = jwt.verify<T>(token);
      if (payload.type !== expectedType) {
        throw new Error('wrong token type');
      }
      return payload;
    } catch {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Token is invalid or expired.',
      });
    }
  }
}
