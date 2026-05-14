import { ForbiddenException } from '@nestjs/common';

import { PremiumGuard } from '../../../src/common/guards/premium.guard';

describe('AI premium gate (T156)', () => {
  let guard: PremiumGuard;

  beforeEach(() => {
    guard = new PremiumGuard();
  });

  it('free user → 403 PREMIUM_REQUIRED on /ai/notes/jobs', () => {
    const ctx = {
      switchToHttp: () => ({
        getRequest: () => ({
          user: { id: 'user-1', plan: 'free', emailVerified: true, premiumUntil: null, role: 'user', sessionId: 's1', email: 'test@test.com' },
        }),
      }),
    } as any;

    expect(() => guard.canActivate(ctx)).toThrow(ForbiddenException);
  });

  it('premium user → pass', () => {
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
});
