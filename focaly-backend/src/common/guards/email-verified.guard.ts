import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

import { UsersRepository } from '../../modules/users/users.repository';
import type { CurrentUserPayload } from '../decorators/current-user.decorator';
import { ERROR_CODES } from '../dto/api-response';

@Injectable()
export class EmailVerifiedGuard implements CanActivate {
  constructor(private readonly usersRepository: UsersRepository) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    const user = req.user;

    // Common path: trust a positive JWT claim without hitting the DB.
    if (user?.emailVerified) return true;

    // The access token may have been issued before the user verified their
    // email (the token isn't refreshed on verification). Re-check the source
    // of truth so a freshly-verified user isn't wrongly blocked.
    if (user?.id) {
      const fresh = await this.usersRepository.findActiveById(user.id);
      if (fresh?.emailVerified) return true;
    }

    throw new ForbiddenException({
      code: ERROR_CODES.EMAIL_VERIFICATION_REQUIRED,
      message: 'Please verify your email before changing security-sensitive settings.',
    });
  }
}
