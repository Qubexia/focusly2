export class AiJobCompletedEvent {
  constructor(
    public readonly userId: string,
    public readonly jobId: string,
    public readonly subjectId: string,
    public readonly artifactIds: string[],
  ) {}
}
