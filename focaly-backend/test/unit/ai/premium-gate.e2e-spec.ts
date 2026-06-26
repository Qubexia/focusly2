import { ExecutionContext, ForbiddenException } from '@nestjs/common';

import { PremiumGuard } from '../../../src/common/guards/premium.guard';

const makeCtx = (user: unknown): ExecutionContext =>
  ({
    switchToHttp: () => ({
      getRequest: () => ({ user }),
    }),
  }) as unknown as ExecutionContext;

describe('AI premium gate (T156)', () => {
  let guard: PremiumGuard;

  beforeEach(() => {
    guard = new PremiumGuard();
  });

  // Premium gating is disabled (manual override in PremiumGuard): every
  // authenticated user can access /ai/notes/jobs regardless of plan.

  it('unauthenticated request → 403 PREMIUM_REQUIRED', () => {
    const ctx = makeCtx(undefined);

    expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
  });

  it('free user → pass on /ai/notes/jobs (gating disabled)', () => {
    const ctx = makeCtx({
      id: 'user-1',
      plan: 'free',
      emailVerified: true,
      premiumUntil: null,
      role: 'user',
      sessionId: 's1',
      email: 'test@test.com',
    });

    expect(guard.canActivate(ctx)).toBe(true);
  });

  it('premium user → pass', () => {
    const ctx = makeCtx({
      id: 'user-1',
      plan: 'premium',
      emailVerified: true,
      premiumUntil: new Date(Date.now() + 86400_000),
      role: 'user',
      sessionId: 's1',
      email: 'test@test.com',
    });

    expect(guard.canActivate(ctx)).toBe(true);
  });
});
