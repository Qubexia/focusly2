export type SubscriptionStatus =
  | 'trialing'
  | 'active'
  | 'past_due'
  | 'canceled'
  | 'expired';

export class SubscriptionChangedEvent {
  constructor(
    public readonly userId: string,
    public readonly status: SubscriptionStatus,
    public readonly currentPeriodEnd: Date | null,
    public readonly provider: 'stripe' | 'google_play' | 'app_store',
  ) {}
}
