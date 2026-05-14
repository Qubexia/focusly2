import { Injectable, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ERROR_CODES } from '../../common/dto/api-response';
import { PlannedItemChangedEvent } from '../../shared/events/planned-item-changed.event';
import { PlannedItemCompletedEvent } from '../../shared/events/planned-item-completed.event';
import { PlannedItemDeletedEvent } from '../../shared/events/planned-item-deleted.event';
import { UsersRepository } from '../users/users.repository';

import {
  CreatePlannedItemDto,
  UpdatePlannedItemDto,
} from './dto';
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
      recurrence: dto.recurrence as any ?? 'once',
      reminderMinutesBefore: dto.reminderMinutesBefore ?? 15,
      reminderEnabled: dto.reminderEnabled ?? true,
      rewardPoints: dto.rewardPoints ?? 0,
    });

    this.eventBus.publish(
      new PlannedItemChangedEvent(userId, item.id, kind),
    );

    return item;
  }

  async findAll(userId: string, kind: PlannedItemKind, includeCompleted?: string) {
    return this.repository.findAllByUser(userId, kind, includeCompleted === 'true');
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
    if (dto.reminderMinutesBefore !== undefined) update.reminderMinutesBefore = dto.reminderMinutesBefore;
    if (dto.reminderEnabled !== undefined) update.reminderEnabled = dto.reminderEnabled;
    if (dto.rewardPoints !== undefined) update.rewardPoints = dto.rewardPoints;

    const updated = await this.repository.updateById(id, { $set: update });
    if (!updated) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    this.eventBus.publish(
      new PlannedItemChangedEvent(userId, id, kind),
    );

    return updated;
  }

  async complete(userId: string, kind: PlannedItemKind, id: string) {
    const item = await this.repository.findById(id);
    if (!item || item.userId.toString() !== userId || item.kind !== kind) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: `${kind} was not found.`,
      });
    }

    if (item.completed) return item;

    const updated = await this.repository.updateById(id, {
      $set: { completed: true, completedAt: new Date() },
    });

    const points = item.rewardPoints || 0;
    if (points > 0) {
      await this.usersRepository.updateOne({ _id: userId }, { $inc: { totalPoints: points } });
    }

    this.eventBus.publish(
      new PlannedItemCompletedEvent(userId, id, kind, points),
    );

    return updated;
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

    this.eventBus.publish(
      new PlannedItemDeletedEvent(userId, id, kind),
    );
  }
}
