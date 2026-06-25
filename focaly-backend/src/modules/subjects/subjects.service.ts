import { Injectable, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ERROR_CODES } from '../../common/dto/api-response';

import { ChaptersRepository } from './chapters.repository';
import { CreateSubjectDto, UpdateSubjectDto } from './dto';
import { SubjectsRepository } from './subjects.repository';

@Injectable()
export class SubjectsService {
  constructor(
    private readonly subjectsRepository: SubjectsRepository,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly eventBus: EventBus,
  ) {}

  async create(userId: string, dto: CreateSubjectDto) {
    return this.subjectsRepository.create({ userId, ...dto });
  }

  async findAll(userId: string, includeArchived = false) {
    return this.subjectsRepository.findAllByUser(userId, includeArchived);
  }

  async findOne(userId: string, id: string) {
    const subject = await this.subjectsRepository.findActiveById(userId, id);
    if (!subject) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Subject was not found.',
      });
    }
    return subject;
  }

  async update(userId: string, id: string, dto: UpdateSubjectDto) {
    const subject = await this.subjectsRepository.findActiveById(userId, id);
    if (!subject) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Subject was not found.',
      });
    }

    const updated = await this.subjectsRepository.updateById(id, {
      $set: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.color !== undefined && { color: dto.color }),
        ...(dto.icon !== undefined && { icon: dto.icon }),
        ...(dto.dailyTargetMinutes !== undefined && { dailyTargetMinutes: dto.dailyTargetMinutes }),
        ...(dto.goalType !== undefined && { goalType: dto.goalType }),
        ...(dto.goalDays !== undefined && { goalDays: dto.goalDays }),
        ...(dto.isArchived !== undefined && { isArchived: dto.isArchived }),
      },
    });
    if (!updated) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Subject was not found.',
      });
    }
    return updated;
  }

  async remove(userId: string, id: string): Promise<void> {
    const subject = await this.subjectsRepository.findActiveById(userId, id);
    if (!subject) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Subject was not found.',
      });
    }

    await this.chaptersRepository.deleteBySubject(id);
    await this.subjectsRepository.softDelete(id);
  }

  async getProgress(subjectId: string) {
    const stats = await this.chaptersRepository.getStats(subjectId);
    return {
      progressPercent: stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0,
      chaptersTotal: stats.total,
      chaptersCompleted: stats.completed,
    };
  }
}
