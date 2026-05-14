export class PlannedItemChangedEvent {
  constructor(
    public readonly userId: string,
    public readonly itemId: string,
    public readonly kind: 'task' | 'revision' | 'lecture' | 'exam',
  ) {}
}
