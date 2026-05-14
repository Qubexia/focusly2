import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

import { ERROR_CODES } from '../dto/api-response';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';

@Injectable()
export class EmailVerifiedGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    if (req.user?.emailVerified) return true;
    throw new ForbiddenException({
      code: ERROR_CODES.EMAIL_VERIFICATION_REQUIRED,
      message: 'Please verify your email before changing security-sensitive settings.',
    });
  }
}
