export type ScheduleChangeKind = 'created' | 'updated' | 'deleted';

export class ScheduleChangedEvent {
  constructor(
    public readonly userId: string,
    public readonly scheduleId: string,
    public readonly kind: ScheduleChangeKind,
  ) {}
}
