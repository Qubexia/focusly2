import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface CurrentUserPayload {
  id: string;
  email: string;
  plan: 'free' | 'premium';
  emailVerified: boolean;
  premiumUntil?: Date | null;
  role: 'user' | 'admin';
  sessionId: string;
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): CurrentUserPayload | undefined => {
    const req = ctx.switchToHttp().getRequest<{ user?: CurrentUserPayload }>();
    return req.user;
  },
);
