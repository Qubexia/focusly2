import { ForbiddenException } from '@nestjs/common';

import { PremiumGuard } from '../../src/common/guards/premium.guard';

describe('Premium gate (e2e)', () => {
  let guard: PremiumGuard;

  beforeEach(() => {
    guard = new PremiumGuard();
  });

  it('free user → 403 PREMIUM_REQUIRED', () => {
    const ctx = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: { id: 'user-1', plan: 'free', emailVerified: true, premiumUntil: null, role: 'user', sessionId: 's1', email: 'test@test.com' },
        }),
      }),
    } as any;

    expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
  });

  it('premium user with valid premiumUntil → pass', () => {
    const ctx = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: {
            id: 'user-1',
            plan: 'premium',
            emailVerified: true,
            premiumUntil: new Date(Date.now() + 86400_000),
            role: 'user',
            sessionId: 's1',
            email: 'test@test.com',
          },
        }),
      }),
    } as any;

    expect(guard.canActivate(ctx)).toBe(true);
  });

  it('expired premium → 403 PREMIUM_REQUIRED', () => {
    const ctx = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: {
            id: 'user-1',
            plan: 'premium',
            emailVerified: true,
            premiumUntil: new Date(Date.now() - 86400_000),
            role: 'user',
            sessionId: 's1',
            email: 'test@test.com',
          },
        }),
      }),
    } as any;

    expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
  });
});
