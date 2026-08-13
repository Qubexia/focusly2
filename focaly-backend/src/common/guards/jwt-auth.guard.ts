import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';

import { AuthSessionsRepository } from '../../modules/auth/auth-sessions.repository';
import { JwtService } from '../../modules/auth/jwt.service';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { ERROR_CODES } from '../dto/api-response';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwtService: JwtService,
    private readonly authSessionsRepository: AuthSessionsRepository,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const req = context.switchToHttp().getRequest<Request & { user?: CurrentUserPayload }>();
    const token = extractBearerToken(req);
    if (!token) {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Access token is required.',
      });
    }

    const payload = this.jwtService.verifyAccessToken(token);

    // A valid signature is not enough: logout, logout-all, session revocation
    // and password reset all revoke the session, and the access token issued
    // against it must stop working immediately rather than at its expiry.
    const session = await this.authSessionsRepository.findActiveById(payload.sessionId);
    if (!session || session.userId.toString() !== payload.sub) {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Session is no longer active. Please sign in again.',
      });
    }

    req.user = {
      id: payload.sub,
      email: payload.email,
      plan: payload.plan,
      emailVerified: payload.emailVerified,
      premiumUntil: payload.premiumUntil ? new Date(payload.premiumUntil) : null,
      role: payload.role,
      sessionId: payload.sessionId,
    };

    return true;
  }
}

export function extractBearerToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return null;
  }

  return header.slice(7).trim() || null;
}
