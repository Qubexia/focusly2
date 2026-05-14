import { derivePlanForClaims } from '../../../src/modules/auth/jwt.service';

describe('derivePlanForClaims', () => {
  it('keeps premium when premiumUntil is in the future', () => {
    expect(
      derivePlanForClaims({
        id: 'user-1',
        email: 'student@example.com',
        role: 'user',
        plan: 'premium',
        premiumUntil: new Date(Date.now() + 60_000),
        emailVerified: true,
      }),
    ).toBe('premium');
  });

  it('downgrades expired premium claims to free', () => {
    expect(
      derivePlanForClaims({
        id: 'user-1',
        email: 'student@example.com',
        role: 'user',
        plan: 'premium',
        premiumUntil: new Date(Date.now() - 60_000),
        emailVerified: true,
      }),
    ).toBe('free');
  });
});
