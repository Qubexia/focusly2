/**
 * Emitted when a study-schedule occurrence is marked complete. Used (among other
 * things) to advance the user's daily streak, the same way a finished pomodoro
 * session does.
 */
export class StudyDayCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly scheduleId: string,
    public readonly date: string,
    public readonly completedAt: Date,
  ) {}
}
