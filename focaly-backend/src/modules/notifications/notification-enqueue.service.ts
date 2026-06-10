import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Queue } from 'bullmq';

import { redisDisabled } from '../../config/runtime-flags';
import { QUEUE_NOTIFICATIONS } from '../../infrastructure/queue/queue.constants';

import { NotificationJobsRepository } from './notification-jobs.repository';
import { DispatchJobData, NotificationsWorker } from './workers/notifications.worker';

@Injectable()
export class NotificationEnqueueService {
  private readonly logger = new Logger(NotificationEnqueueService.name);

  constructor(
    private readonly jobsRepo: NotificationJobsRepository,
    @InjectQueue(QUEUE_NOTIFICATIONS)
    private readonly queue: Queue,
    private readonly notificationsWorker: NotificationsWorker,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async enqueuePendingJobs(): Promise<void> {
    const windowEnd = new Date(Date.now() + 10 * 60 * 1000);
    const jobs = await this.jobsRepo.findPendingBefore(windowEnd);

    if (jobs.length === 0) return;

    this.logger.log(`Enqueueing ${jobs.length} pending notification jobs`);

    for (const job of jobs) {
      const jobId = String(job._id);
      await this.jobsRepo.markQueued(jobId);

      const delayMs = Math.max(0, job.scheduledAt.getTime() - Date.now());
      const payload: DispatchJobData = {
        jobId,
        userId: job.userId,
        title: job.title,
        body: job.body,
        category: job.category,
      };

      if (redisDisabled) {
        const dispatch = (): void => {
          void this.notificationsWorker.dispatchNotification(payload).catch((err: unknown) => {
            const msg = err instanceof Error ? err.message : 'Unknown error';
            this.logger.error(`Inline notification job ${jobId} failed: ${msg}`);
          });
        };

        if (delayMs > 0) {
          setTimeout(dispatch, delayMs);
        } else {
          void dispatch();
        }
        continue;
      }

      await this.queue.add('dispatch', payload, {
        delay: delayMs,
        attempts: 5,
        backoff: { type: 'exponential', delay: 30_000 },
      });
    }
  }
}
