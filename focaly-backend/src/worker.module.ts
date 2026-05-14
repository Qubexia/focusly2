import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';

import { configLoaders } from './config/configuration';
import { validationSchema } from './config/validation.schema';
import { DatabaseModule } from './infrastructure/database/database.module';
import { FcmModule } from './infrastructure/fcm/fcm.module';
import { LoggerModule } from './infrastructure/logger/logger.module';
import { MailerModule } from './infrastructure/mailer/mailer.module';
import { QueueModule } from './infrastructure/queue/queue.module';
import { RedisModule } from './infrastructure/redis/redis.module';
import { StorageModule } from './infrastructure/storage/s3.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AiModule } from './modules/ai/ai.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { StreaksModule } from './modules/streaks/streaks.module';
import { SubscriptionModule } from './modules/subscription/subscription.module';
import { MaintenanceModule } from './modules/maintenance/maintenance.module';
import { EventBusModule } from './shared/events/event-bus.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: configLoaders,
      validationSchema,
      validationOptions: { abortEarly: true },
    }),
    ScheduleModule.forRoot(),
    LoggerModule,
    DatabaseModule,
    RedisModule,
    QueueModule,
    FcmModule,
    StorageModule,
    MailerModule,
    EventBusModule,
    StreaksModule,
    AnalyticsModule,
    AiModule,
    SubscriptionModule,
    NotificationsModule,
    MaintenanceModule,
  ],
})
export class WorkerModule {}
