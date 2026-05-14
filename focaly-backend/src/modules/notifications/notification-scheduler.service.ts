import { Injectable, Logger } from '@nestjs/common';

import { NotificationJobsRepository } from './notification-jobs.repository';

@Injectable()
export class NotificationSchedulerService {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(
    private readonly jobsRepo: NotificationJobsRepository,
  ) {}

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
  ): Promise<void> {
    await this.jobsRepo.create({
      userId,
      refType: 'planned_item',
      refId: itemId,
      category: 'reminder',
      scheduledAt,
      title: 'Planned item reminder',
      body: 'You have a planned item due soon.',
    });
    this.logger.log(`Planned item reminder scheduled: ${itemId}`);
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
