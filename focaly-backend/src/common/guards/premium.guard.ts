import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { ERROR_CODES } from '../dto/api-response';

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

    // MANUAL OVERRIDE: premium gating disabled — all authenticated users get
    // access for free (mirrors the client-side override in
    // premium_status.dart `hasPremiumAccess`). To restore real gating, delete
    // the two lines below.
    const premiumGatingDisabled = true as boolean;
    if (premiumGatingDisabled) return true;

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
