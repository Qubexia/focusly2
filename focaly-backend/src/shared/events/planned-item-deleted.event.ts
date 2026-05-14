export class PlannedItemDeletedEvent {
  constructor(
    public readonly userId: string,
    public readonly itemId: string,
    public readonly kind: 'task' | 'revision' | 'lecture' | 'exam',
  ) {}
}
