import { Injectable, Logger } from '@nestjs/common';

import { NotificationJobsRepository } from './notification-jobs.repository';

@Injectable()
export class NotificationSchedulerService {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(private readonly jobsRepo: NotificationJobsRepository) {}

  async scheduleScheduleReminder(
    userId: string,
    scheduleId: string,
    scheduledAt: Date,
  ): Promise<void> {
    await this.jobsRepo.create({
      userId,
      refType: 'study_schedule',
      refId: scheduleId,
      category: 'reminder',
      scheduledAt,
      title: 'Study schedule reminder',
      body: 'You have a scheduled study session coming up.',
    });
    this.logger.log(`Schedule reminder scheduled: ${scheduleId}`);
  }

  async schedulePlannedItemReminder(
    userId: string,
    itemId: string,
    scheduledAt: Date,
    title = 'Planned item reminder',
    body = 'You have a planned item due soon.',
  ): Promise<void> {
    await this.jobsRepo.create({
      userId,
      refType: 'planned_item',
      refId: itemId,
      category: 'reminder',
      scheduledAt,
      title,
      body,
    });
    this.logger.log(`Planned item reminder scheduled: ${itemId} at ${scheduledAt.toISOString()}`);
  }

  async syncPlannedItemReminders(item: {
    userId: string;
    id: string;
    title: string;
    plannedAt: Date;
    reminderMinutesBefore: number;
    reminderEnabled: boolean;
    completed: boolean;
  }): Promise<void> {
    await this.jobsRepo.cancelByRef('planned_item', item.id);

    if (item.completed || !item.reminderEnabled) {
      return;
    }

    const now = new Date();
    const due = item.plannedAt;

    if (item.reminderMinutesBefore > 0) {
      const remindAt = new Date(due.getTime() - item.reminderMinutesBefore * 60_000);
      if (remindAt > now) {
        await this.schedulePlannedItemReminder(
          item.userId,
          item.id,
          remindAt,
          item.title,
          `Due in ${item.reminderMinutesBefore} minutes`,
        );
      }
    }

    if (due > now) {
      await this.schedulePlannedItemReminder(
        item.userId,
        item.id,
        due,
        item.title,
        'This item is due now.',
      );
    }
  }

  async syncScheduleReminder(schedule: {
    userId: string;
    id: string;
    title: string;
    startAt: Date;
    reminderMinutesBefore: number;
    reminderEnabled: boolean;
    isActive: boolean;
  }): Promise<void> {
    await this.jobsRepo.cancelByRef('study_schedule', schedule.id);

    if (!schedule.isActive || !schedule.reminderEnabled) {
      return;
    }

    const remindAt = new Date(schedule.startAt.getTime() - schedule.reminderMinutesBefore * 60_000);
    if (remindAt <= new Date()) {
      return;
    }

    await this.jobsRepo.create({
      userId: schedule.userId,
      refType: 'study_schedule',
      refId: schedule.id,
      category: 'reminder',
      scheduledAt: remindAt,
      title: schedule.title,
      body: `Study session starts in ${schedule.reminderMinutesBefore} minutes`,
    });
    this.logger.log(`Schedule reminder synced: ${schedule.id}`);
  }

  cancelByRef(refType: string, refId: string): Promise<void> {
    return this.jobsRepo.cancelByRef(refType, refId);
  }

  async scheduleRewardNotification(userId: string, code: string, points: number): Promise<void> {
    await this.jobsRepo.create({
      userId,
      refType: 'system',
      refId: `${userId}-reward-${code}-${Date.now()}`,
      category: 'reward',
      scheduledAt: new Date(),
      title: `Reward Unlocked: ${code}`,
      body: `You earned a new milestone! +${points} points`,
    });
    this.logger.log(`Reward notification scheduled for user ${userId}: ${code}`);
  }
}
