import { Injectable, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ERROR_CODES } from '../../common/dto/api-response';
import { PlannedItemChangedEvent } from '../../shared/events/planned-item-changed.event';
import { PlannedItemCompletedEvent } from '../../shared/events/planned-item-completed.event';
import { PlannedItemDeletedEvent } from '../../shared/events/planned-item-deleted.event';
import { UsersRepository } from '../users/users.repository';

import { CreatePlannedItemDto, UpdatePlannedItemDto } from './dto';
import { PlannedItemsRepository } from './planned-items.repository';
import { PlannedItemKind } from './schemas/planned-item.schema';

@Injectable()
export class PlannedItemsService {
  constructor(
    private readonly repository: PlannedItemsRepository,
    private readonly usersRepository: UsersRepository,
    private readonly eventBus: EventBus,
  ) {}

  async create(userId: string, kind: PlannedItemKind, dto: CreatePlannedItemDto) {
    const item = await this.repository.create({
      userId,
      kind,
      title: dto.title,
      subjectId: dto.subjectId ?? null,
      notes: dto.notes ?? null,
      plannedAt: new Date(dto.plannedAt),
      durationMinutes: dto.durationMinutes ?? null,
      recurrence: (dto.recurrence as 'daily' | 'weekly' | 'once' | undefined) ?? 'once',
      daysOfWeek: dto.daysOfWeek ?? [],
      recurrenceEndAt: dto.recurrenceEndAt ? new Date(dto.recurrenceEndAt) : null,
      reminderMinutesBefore: dto.reminderMinutesBefore ?? 15,
      reminderEnabled: dto.reminderEnabled ?? true,
      rewardPoints: dto.rewardPoints ?? 0,
    });

    this.eventBus.publish(new PlannedItemChangedEvent(userId, String(item.id), kind));

    return item;
  }

  async findAll(
    userId: string,
    kind: PlannedItemKind,
    options: {
      subjectId?: string;
      from?: string;
      to?: string;
      includeCompleted?: string;
    } = {},
  ) {
    return this.repository.findAllByUser(userId, kind, {
      subjectId: options.subjectId,
      from: options.from,
      to: options.to,
      includeCompleted: options.includeCompleted === 'true',
    });
  }

  async findOne(userId: string, kind: PlannedItemKind, id: string) {
    const item = await this.repository.findById(id);
    if (!item || item.userId.toString() !== userId || item.kind !== kind) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }
    return item;
  }

  async update(userId: string, kind: PlannedItemKind, id: string, dto: UpdatePlannedItemDto) {
    const item = await this.repository.findById(id);
    if (!item || item.userId.toString() !== userId || item.kind !== kind) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    const update: Record<string, unknown> = {};
    if (dto.title !== undefined) update.title = dto.title;
    if (dto.subjectId !== undefined) update.subjectId = dto.subjectId;
    if (dto.notes !== undefined) update.notes = dto.notes;
    if (dto.plannedAt !== undefined) update.plannedAt = new Date(dto.plannedAt);
    if (dto.durationMinutes !== undefined) update.durationMinutes = dto.durationMinutes;
    if (dto.recurrence !== undefined) update.recurrence = dto.recurrence;
    if (dto.daysOfWeek !== undefined) update.daysOfWeek = dto.daysOfWeek;
    if (dto.recurrenceEndAt !== undefined)
      update.recurrenceEndAt = dto.recurrenceEndAt ? new Date(dto.recurrenceEndAt) : null;
    if (dto.reminderMinutesBefore !== undefined)
      update.reminderMinutesBefore = dto.reminderMinutesBefore;
    if (dto.reminderEnabled !== undefined) update.reminderEnabled = dto.reminderEnabled;
    if (dto.rewardPoints !== undefined) update.rewardPoints = dto.rewardPoints;

    const updated = await this.repository.updateById(id, { $set: update });
    if (!updated) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    this.eventBus.publish(new PlannedItemChangedEvent(userId, id, kind));

    return updated;
  }

  async complete(userId: string, kind: PlannedItemKind, id: string, date?: string) {
    const item = await this.repository.findById(id);
    if (!item || item.userId.toString() !== userId || item.kind !== kind) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    // A recurring item is completed one occurrence at a time, so ticking off
    // this Saturday leaves next Saturday's occurrence outstanding.
    if (item.recurrence !== 'once') {
      const occurrenceDate = normalizeOccurrenceDate(date);
      if (item.completedDates?.includes(occurrenceDate)) return item;

      const updated = await this.repository.completeOccurrence(id, occurrenceDate);
      await this.awardPoints(userId, kind, id, item.rewardPoints || 0);
      return updated;
    }

    if (item.completed) return item;

    const updated = await this.repository.updateById(id, {
      $set: { completed: true, completedAt: new Date() },
    });

    await this.awardPoints(userId, kind, id, item.rewardPoints || 0);

    return updated;
  }

  private async awardPoints(
    userId: string,
    kind: PlannedItemKind,
    id: string,
    points: number,
  ): Promise<void> {
    if (points > 0) {
      await this.usersRepository.updateOne({ _id: userId }, { $inc: { totalPoints: points } });
    }

    this.eventBus.publish(new PlannedItemCompletedEvent(userId, id, kind, points));
  }

  async remove(userId: string, kind: PlannedItemKind, id: string) {
    const item = await this.repository.findById(id);
    if (!item || item.userId.toString() !== userId || item.kind !== kind) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    await this.repository.hardDelete(id);

    this.eventBus.publish(new PlannedItemDeletedEvent(userId, id, kind));
  }
}

/**
 * Occurrence keys are plain `YYYY-MM-DD` in the viewer's own calendar, so the
 * client sends the date it rendered rather than letting the server guess it
 * from a UTC timestamp.
 */
function normalizeOccurrenceDate(date?: string): string {
  if (date && /^\d{4}-\d{2}-\d{2}$/.test(date)) return date;
  return new Date().toISOString().slice(0, 10);
}
