import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Inject } from '@nestjs/common';
import { Job } from 'bullmq';

import { FCM_CLIENT } from '../../../infrastructure/fcm/fcm.tokens';
import type { FcmClient, FcmMessage } from '../../../infrastructure/fcm/fcm.tokens';
import { QUEUE_NOTIFICATIONS } from '../../../infrastructure/queue/queue.constants';
import { AuthSessionsRepository } from '../../auth/auth-sessions.repository';
import { PomodoroRepository } from '../../pomodoro/pomodoro.repository';
import { UsersRepository } from '../../users/users.repository';
import { NotificationJobsRepository } from '../notification-jobs.repository';
import { NotificationsRepository } from '../notifications.repository';

interface DispatchJobData {
  jobId: string;
  userId: string;
  title: string;
  body: string;
  category: string;
}

@Processor(QUEUE_NOTIFICATIONS)
export class NotificationsWorker extends WorkerHost {
  constructor(
    @Inject(FCM_CLIENT)
    private readonly fcmClient: FcmClient,
    private readonly authSessionsRepo: AuthSessionsRepository,
    private readonly usersRepo: UsersRepository,
    private readonly pomodoroRepo: PomodoroRepository,
    private readonly notificationsRepo: NotificationsRepository,
    private readonly jobsRepo: NotificationJobsRepository,
  ) {
    super();
  }

  async process(job: Job<DispatchJobData>): Promise<void> {
    const { jobId, userId, title, body, category } = job.data;

    if (title) {
      await this.notificationsRepo.create({
        userId,
        type: category,
        title,
        body: body ?? null,
      });
    }

    const user = await this.usersRepo.findActiveById(userId);
    if (!user) {
      await this.jobsRepo.markFailed(jobId, 'User not found');
      return;
    }

    if (category === 'reminder' || category === 'streak') {
      const prefKey = category === 'reminder' ? 'reminders' : 'streak';
      if (!user.settings?.notifications?.[prefKey as keyof typeof user.settings.notifications]) {
        await this.jobsRepo.markSent(jobId);
        return;
      }
    }

    if (user.settings?.focusMode) {
      const activeSession = await this.pomodoroRepo.findActiveByUser(userId);
      if (activeSession) {
        await this.jobsRepo.markSent(jobId);
        return;
      }
    }

    const sessions = await this.authSessionsRepo.findActiveByUserId(userId);
    const fcmTokens = sessions
      .map((s) => s.fcmToken)
      .filter((t): t is string => !!t);

    if (fcmTokens.length === 0) {
      await this.jobsRepo.markSent(jobId);
      return;
    }

    const messages: FcmMessage[] = fcmTokens.map((token) => ({
      token,
      title: title ?? 'Notification',
      body: body ?? '',
    }));

    const result = await this.fcmClient.send(messages);

    for (const failure of result.failureTokens) {
      if (failure.permanent) {
        const session = sessions.find((s) => s.fcmToken === failure.token);
        if (session) {
          await this.authSessionsRepo.setFcmToken(session.id, null);
        }
      }
    }

    await this.jobsRepo.markSent(jobId);
  }
}
