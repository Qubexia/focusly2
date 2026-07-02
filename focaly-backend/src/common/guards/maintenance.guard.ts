import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { PlatformSettingsService } from '../../modules/platform-settings/platform-settings.service';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { ROLES_KEY, type Role } from '../decorators/roles.decorator';
import { ERROR_CODES } from '../dto/api-response';

@Injectable()
export class MaintenanceGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (isPublic) return true;

    const requiredRoles = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    if (requiredRoles?.includes('admin') && req.user?.role === 'admin') {
      return true;
    }

    const settings = await this.platformSettings.resolve();
    if (!settings.maintenanceMode) return true;

    throw new ServiceUnavailableException({
      code: ERROR_CODES.MAINTENANCE,
      message:
        settings.maintenanceMessage?.trim() ||
        'The service is temporarily unavailable for maintenance.',
    });
  }
}
