export type RewardCode = 'STREAK_3' | 'STREAK_7' | 'STREAK_30' | 'STREAK_100';

export class RewardUnlockedEvent {
  constructor(
    public readonly userId: string,
    public readonly code: RewardCode,
    public readonly points: number,
    public readonly awardedAt: Date,
  ) {}
}
