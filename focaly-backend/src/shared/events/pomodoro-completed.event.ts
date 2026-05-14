export class PomodoroCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly sessionId: string,
    public readonly subjectId: string | null,
    public readonly completedAt: Date,
    public readonly focusMinutes: number,
    public readonly completedCycles: number,
    public readonly totalFocusMinutes: number,
  ) {}
}
