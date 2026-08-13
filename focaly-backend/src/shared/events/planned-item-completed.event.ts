export class PlannedItemCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly itemId: string,
    public readonly kind: 'task' | 'revision' | 'lecture' | 'exam',
    public readonly rewardPoints: number,
    /**
     * `YYYY-MM-DD` of the occurrence that was ticked off, in the user's own
     * calendar. A recurring item can be completed for a day other than today,
     * so analytics has to credit that day and not the moment of the tap.
     */
    public readonly occurrenceDate: string,
  ) {}
}
