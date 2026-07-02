import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from '../auth/auth.module';
import { PlannedItemsModule } from '../planned-items/planned-items.module';
import { PomodoroModule } from '../pomodoro/pomodoro.module';
import { StudySchedulesModule } from '../study-schedules/study-schedules.module';
import { UsersModule } from '../users/users.module';

import { PlannedItemChangedHandler } from './handlers/planned-item-changed.handler';
import { PlannedItemCompletedHandler } from './handlers/planned-item-completed.handler';
import { PlannedItemDeletedHandler } from './handlers/planned-item-deleted.handler';
import { RewardUnlockedHandler } from './handlers/reward-unlocked.handler';
import { ScheduleChangedHandler } from './handlers/schedule-changed.handler';
import { NotificationEnqueueService } from './notification-enqueue.service';
import { NotificationJobsRepository } from './notification-jobs.repository';
import { NotificationSchedulerService } from './notification-scheduler.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsRepository } from './notifications.repository';
import { NotificationJob, NotificationJobSchema } from './schemas/notification-job.schema';
import { Notification, NotificationSchema } from './schemas/notification.schema';
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
    PlannedItemsModule,
    StudySchedulesModule,
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
    PlannedItemCompletedHandler,
    PlannedItemDeletedHandler,
    RewardUnlockedHandler,
  ],
  exports: [NotificationsRepository, NotificationJobsRepository],
})
export class NotificationsModule {}
