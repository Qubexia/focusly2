import { Injectable, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ERROR_CODES } from '../../common/dto/api-response';
import { ScheduleChangedEvent } from '../../shared/events/schedule-changed.event';
import { StudyDayCompletedEvent } from '../../shared/events/study-day-completed.event';

import { CreateScheduleDto, UpdateScheduleDto } from './dto';
import { StudySchedulesRepository } from './study-schedules.repository';

export interface ScheduleCompletionView {
  scheduleId: string;
  date: string;
}

@Injectable()
export class StudySchedulesService {
  constructor(
    private readonly repository: StudySchedulesRepository,
    private readonly eventBus: EventBus,
  ) {}

  async create(userId: string, subjectId: string, dto: CreateScheduleDto) {
    const schedule = await this.repository.create({
      userId,
      subjectId,
      title: dto.title,
      startAt: new Date(dto.startAt),
      endAt: dto.endAt ? new Date(dto.endAt) : null,
      daysOfWeek: dto.daysOfWeek,
      rrule: dto.rrule ?? null,
      reminderMinutesBefore: dto.reminderMinutesBefore ?? 15,
      reminderEnabled: dto.reminderEnabled ?? true,
    });
    this.eventBus.publish(new ScheduleChangedEvent(userId, String(schedule._id), 'created'));
    return schedule;
  }

  async findAll(userId: string, from: string, to: string) {
    return this.repository.findActiveByUserInRange(userId, new Date(from), new Date(to));
  }

  async findOne(userId: string, id: string) {
    const schedule = await this.repository.findById(id);
    if (!schedule || schedule.userId.toString() !== userId) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Schedule was not found.',
      });
    }
    return schedule;
  }

  async update(userId: string, id: string, dto: UpdateScheduleDto) {
    await this.findOne(userId, id);
    const update: Record<string, unknown> = {};
    if (dto.title !== undefined) update.title = dto.title;
    if (dto.startAt !== undefined) update.startAt = new Date(dto.startAt);
    if (dto.endAt !== undefined) update.endAt = dto.endAt ? new Date(dto.endAt) : null;
    if (dto.daysOfWeek !== undefined) update.daysOfWeek = dto.daysOfWeek;
    if (dto.rrule !== undefined) update.rrule = dto.rrule;
    if (dto.reminderMinutesBefore !== undefined)
      update.reminderMinutesBefore = dto.reminderMinutesBefore;
    if (dto.reminderEnabled !== undefined) update.reminderEnabled = dto.reminderEnabled;
    if (dto.isActive !== undefined) update.isActive = dto.isActive;

    const updated = await this.repository.updateById(id, { $set: update });
    this.eventBus.publish(new ScheduleChangedEvent(userId, id, 'updated'));
    return updated;
  }

  async remove(userId: string, id: string): Promise<void> {
    await this.findOne(userId, id);
    await this.repository.deleteById(id);
    await this.repository.deleteCompletionsBySchedule(id);
    this.eventBus.publish(new ScheduleChangedEvent(userId, id, 'deleted'));
  }

  async complete(userId: string, id: string, date: string): Promise<ScheduleCompletionView> {
    // Ownership check (throws NotFound if the schedule isn't the user's).
    await this.findOne(userId, id);
    await this.repository.upsertCompletion(userId, id, date);
    // Completing a study session counts toward the daily streak (idempotent per
    // day on the handler side, so it is safe even if a pomodoro also fired).
    this.eventBus.publish(new StudyDayCompletedEvent(userId, id, date, new Date()));
    return { scheduleId: id, date };
  }

  async listCompletions(
    userId: string,
    from: string,
    to: string,
  ): Promise<ScheduleCompletionView[]> {
    const completions = await this.repository.findCompletionsByUserInRange(userId, from, to);
    return completions.map((c) => ({ scheduleId: String(c.scheduleId), date: c.date }));
  }
}
