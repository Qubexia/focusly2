import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { ChapterCompletedEvent } from '../../../shared/events/chapter-completed.event';
import { ChaptersRepository } from '../chapters.repository';
import { SubjectsRepository } from '../subjects.repository';

@EventsHandler(ChapterCompletedEvent)
export class RecomputeProgressHandler implements IEventHandler<ChapterCompletedEvent> {
  constructor(
    private readonly subjectsRepository: SubjectsRepository,
    private readonly chaptersRepository: ChaptersRepository,
  ) {}

  async handle(event: ChapterCompletedEvent): Promise<void> {
    const stats = await this.chaptersRepository.getStats(event.subjectId);
    const progressPercent = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0;

    await this.subjectsRepository.updateById(event.subjectId, {
      $set: { progressPercent },
    });
  }
}
