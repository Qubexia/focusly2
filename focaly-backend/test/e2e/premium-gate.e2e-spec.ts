import { ExecutionContext, ForbiddenException } from '@nestjs/common';

import { PremiumGuard } from '../../src/common/guards/premium.guard';

const makeCtx = (user: unknown): ExecutionContext =>
  ({
    switchToHttp: () => ({
      getRequest: () => ({ user }),
    }),
  }) as unknown as ExecutionContext;

describe('Premium gate (e2e)', () => {
  let guard: PremiumGuard;

  beforeEach(() => {
    guard = new PremiumGuard();
  });

  // Premium gating is disabled (manual override in PremiumGuard): every
  // authenticated user passes regardless of plan. Only unauthenticated
  // requests are rejected.

  it('unauthenticated request → 403 PREMIUM_REQUIRED', () => {
    const ctx = makeCtx(undefined);

    expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
  });

  it('free user → pass (gating disabled)', () => {
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

  it('premium user with valid premiumUntil → pass', () => {
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

  it('expired premium → pass (gating disabled)', () => {
    const ctx = makeCtx({
      id: 'user-1',
      plan: 'premium',
      emailVerified: true,
      premiumUntil: new Date(Date.now() - 86400_000),
      role: 'user',
      sessionId: 's1',
      email: 'test@test.com',
    });

    expect(guard.canActivate(ctx)).toBe(true);
  });
});
