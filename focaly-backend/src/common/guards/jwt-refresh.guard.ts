import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';

import { JwtService, RefreshTokenClaims } from '../../modules/auth/jwt.service';
import { ERROR_CODES } from '../dto/api-response';

import { extractBearerToken } from './jwt-auth.guard';

@Injectable()
export class JwtRefreshGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context
      .switchToHttp()
      .getRequest<Request & { refreshTokenPayload?: RefreshTokenClaims }>();
    const body = req.body as { refreshToken?: string } | undefined;
    const token = body?.refreshToken ?? extractBearerToken(req);
    if (!token) {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Refresh token is required.',
      });
    }

    req.refreshTokenPayload = this.jwtService.verifyRefreshToken(token);
    return true;
  }
}
