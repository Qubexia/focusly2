import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

import { PlatformSettingsService } from '../../modules/platform-settings/platform-settings.service';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { ERROR_CODES } from '../dto/api-response';

@Injectable()
export class PremiumGuard implements CanActivate {
  constructor(private readonly platformSettings: PlatformSettingsService) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    const user = req.user;
    if (!user) {
      throw new ForbiddenException({
        code: ERROR_CODES.PREMIUM_REQUIRED,
        message: 'Upgrade to premium to access this feature.',
      });
    }

    const settings = await this.platformSettings.resolve();
    if (!settings.premiumGatingEnabled) return true;

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
