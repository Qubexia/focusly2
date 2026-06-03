import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { ROLES_KEY, type Role } from '../decorators/roles.decorator';
import { ERROR_CODES } from '../dto/api-response';

/**
 * Enforces role-based access on top of the global JwtAuthGuard.
 * Reads roles declared via @Roles(...) and checks req.user.role against them.
 * Mirrors the pattern in premium.guard.ts.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    const user = req.user;

    if (user && requiredRoles.includes(user.role)) {
      return true;
    }

    throw new ForbiddenException({
      code: ERROR_CODES.ADMIN_REQUIRED,
      message: 'Administrator privileges are required for this action.',
    });
  }
}
