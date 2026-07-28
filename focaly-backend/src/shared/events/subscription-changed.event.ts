export type SubscriptionStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'expired';

export class SubscriptionChangedEvent {
  constructor(
    public readonly userId: string,
    public readonly status: SubscriptionStatus,
    public readonly currentPeriodEnd: Date | null,
    /** `stripe` only ever comes from legacy rows; the integration was removed. */
    public readonly provider: 'paymob' | 'google_play' | 'app_store' | 'stripe',
  ) {}
}
