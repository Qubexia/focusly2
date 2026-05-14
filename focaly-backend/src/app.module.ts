import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';

import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { ThrottlerBehindProxyGuard } from './common/guards/throttler-behind-proxy.guard';
import { AuditLogMiddleware } from './common/middleware/audit-log.middleware';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';
import { configLoaders } from './config/configuration';
import { validationSchema } from './config/validation.schema';
import { DatabaseModule } from './infrastructure/database/database.module';
import { FcmModule } from './infrastructure/fcm/fcm.module';
import { LoggerModule } from './infrastructure/logger/logger.module';
import { MailerModule } from './infrastructure/mailer/mailer.module';
import { QueueModule } from './infrastructure/queue/queue.module';
import { RedisModule } from './infrastructure/redis/redis.module';
import { StorageModule } from './infrastructure/storage/s3.module';
import { TracingModule } from './infrastructure/tracing/tracing.module';
import { AiModule } from './modules/ai/ai.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { AuthModule } from './modules/auth/auth.module';
import { HealthModule } from './modules/health/health.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PlannedItemsModule } from './modules/planned-items/planned-items.module';
import { PomodoroModule } from './modules/pomodoro/pomodoro.module';
import { StreaksModule } from './modules/streaks/streaks.module';
import { SubscriptionModule } from './modules/subscription/subscription.module';
import { StudySchedulesModule } from './modules/study-schedules/study-schedules.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { SubjectsModule } from './modules/subjects/subjects.module';
import { UsersModule } from './modules/users/users.module';
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
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 60 }]),
    LoggerModule,
    DatabaseModule,
    RedisModule,
    QueueModule,
    FcmModule,
    StorageModule,
    MailerModule,
    TracingModule,
    EventBusModule,
    HealthModule,
    UsersModule,
    AuthModule,
    SubjectsModule,
    StudySchedulesModule,
    SubscriptionModule,
    PlannedItemsModule,
    AnalyticsModule,
    UploadsModule,
    AiModule,
    NotificationsModule,
    PomodoroModule,
    StreaksModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerBehindProxyGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware, AuditLogMiddleware).forRoutes('*');
  }
}
