export class ChapterCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly subjectId: string,
    public readonly chapterId: string,
    public readonly completed: boolean,
  ) {}
}
