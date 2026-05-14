import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Cron, CronExpression } from '@nestjs/schedule';

import { QUEUE_NOTIFICATIONS } from '../../infrastructure/queue/queue.constants';
import { NotificationJobsRepository } from './notification-jobs.repository';

@Injectable()
export class NotificationEnqueueService {
  private readonly logger = new Logger(NotificationEnqueueService.name);

  constructor(
    private readonly jobsRepo: NotificationJobsRepository,
    @InjectQueue(QUEUE_NOTIFICATIONS)
    private readonly queue: Queue,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async enqueuePendingJobs(): Promise<void> {
    const windowEnd = new Date(Date.now() + 10 * 60 * 1000);
    const jobs = await this.jobsRepo.findPendingBefore(windowEnd);

    if (jobs.length === 0) return;

    this.logger.log(`Enqueueing ${jobs.length} pending notification jobs`);

    for (const job of jobs) {
      await this.jobsRepo.markQueued(job.id);

      const delayMs = Math.max(0, job.scheduledAt.getTime() - Date.now());
      await this.queue.add(
        'dispatch',
        {
          jobId: job.id,
          userId: job.userId,
          title: job.title,
          body: job.body,
          category: job.category,
        },
        {
          delay: delayMs,
          attempts: 5,
          backoff: { type: 'exponential', delay: 30_000 },
        },
      );
    }
  }
}
