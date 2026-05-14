import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

import { ERROR_CODES } from '../dto/api-response';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';

@Injectable()
export class PremiumGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    const user = req.user;
    if (!user) {
      throw new ForbiddenException({
        code: ERROR_CODES.PREMIUM_REQUIRED,
        message: 'Upgrade to premium to access this feature.',
      });
    }
    if (
      user.plan === 'premium' &&
      (user.premiumUntil === undefined ||
        user.premiumUntil === null ||
        new Date(user.premiumUntil) > new Date())
    ) {
      return true;
    }
    throw new ForbiddenException({
      code: ERROR_CODES.PREMIUM_REQUIRED,
      message: 'Upgrade to premium to access this feature.',
    });
  }
}
