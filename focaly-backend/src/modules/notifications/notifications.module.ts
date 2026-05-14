import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '../auth/auth.module';
import { PomodoroModule } from '../pomodoro/pomodoro.module';
import { UsersModule } from '../users/users.module';

import { PlannedItemChangedHandler } from './handlers/planned-item-changed.handler';
import { PlannedItemDeletedHandler } from './handlers/planned-item-deleted.handler';
import { RewardUnlockedHandler } from './handlers/reward-unlocked.handler';
import { ScheduleChangedHandler } from './handlers/schedule-changed.handler';
import { NotificationEnqueueService } from './notification-enqueue.service';
import { NotificationJobsRepository } from './notification-jobs.repository';
import { NotificationSchedulerService } from './notification-scheduler.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsRepository } from './notifications.repository';
import { Notification, NotificationSchema } from './schemas/notification.schema';
import { NotificationJob, NotificationJobSchema } from './schemas/notification-job.schema';
import { NotificationsWorker } from './workers/notifications.worker';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Notification.name, schema: NotificationSchema },
      { name: NotificationJob.name, schema: NotificationJobSchema },
    ]),
    CqrsModule,
    AuthModule,
    UsersModule,
    PomodoroModule,
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsRepository,
    NotificationJobsRepository,
    NotificationSchedulerService,
    NotificationEnqueueService,
    NotificationsWorker,
    ScheduleChangedHandler,
    PlannedItemChangedHandler,
    PlannedItemDeletedHandler,
    RewardUnlockedHandler,
  ],
  exports: [NotificationsRepository, NotificationJobsRepository],
})
export class NotificationsModule {}
