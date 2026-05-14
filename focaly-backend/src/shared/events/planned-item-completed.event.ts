export class PlannedItemCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly itemId: string,
    public readonly kind: 'task' | 'revision' | 'lecture' | 'exam',
    public readonly rewardPoints: number,
  ) {}
}
