import { Injectable } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ChapterCompletedEvent } from '../../shared/events/chapter-completed.event';

import { ChaptersRepository } from './chapters.repository';
import { CreateChapterDto, UpdateChapterDto } from './dto';

@Injectable()
export class ChaptersService {
  constructor(
    private readonly chaptersRepository: ChaptersRepository,
    private readonly eventBus: EventBus,
  ) {}

  async create(userId: string, subjectId: string, dto: CreateChapterDto) {
    return this.chaptersRepository.create({
      subjectId,
      userId,
      title: dto.title,
      order: dto.order,
    });
  }

  async findAll(subjectId: string) {
    return this.chaptersRepository.findBySubject(subjectId);
  }

  async update(userId: string, subjectId: string, chapterId: string, dto: UpdateChapterDto) {
    const chapter = await this.chaptersRepository.findById(subjectId, chapterId);
    if (!chapter) {
      return null;
    }

    const update: Record<string, unknown> = {};
    if (dto.title !== undefined) update.title = dto.title;
    if (dto.order !== undefined) update.order = dto.order;
    if (dto.completed !== undefined) {
      update.completed = dto.completed;
      update.completedAt = dto.completed ? new Date() : null;
    }

    const updated = await this.chaptersRepository.updateById(chapterId, update);
    if (updated && dto.completed !== undefined) {
      this.eventBus.publish(new ChapterCompletedEvent(userId, subjectId, chapterId, dto.completed));
    }
    return updated;
  }
}
