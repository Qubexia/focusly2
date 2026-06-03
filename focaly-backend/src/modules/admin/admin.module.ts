import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AiModule } from '../ai/ai.module';
import { AiJob, AiJobSchema } from '../ai/schemas/ai-job.schema';
import { AnalyticsDaily, AnalyticsDailySchema } from '../analytics/schemas/analytics-daily.schema';
import { AuthModule } from '../auth/auth.module';
import { AuthSession, AuthSessionSchema } from '../auth/schemas/auth-session.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { PlannedItem, PlannedItemSchema } from '../planned-items/schemas/planned-item.schema';
import {
  PomodoroSession,
  PomodoroSessionSchema,
} from '../pomodoro/schemas/pomodoro-session.schema';
import { Streak, StreakSchema } from '../streaks/schemas/streak.schema';
import { Subject, SubjectSchema } from '../subjects/schemas/subject.schema';
import { PaymentEvent, PaymentEventSchema } from '../subscription/schemas/payment-event.schema';
import { Subscription, SubscriptionSchema } from '../subscription/schemas/subscription.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { UsersModule } from '../users/users.module';

import { AdminAiController } from './admin-ai.controller';
import { AdminAnalyticsController } from './admin-analytics.controller';
import { AdminAnalyticsService } from './admin-analytics.service';
import { AdminContentController } from './admin-content.controller';
import { AdminContentService } from './admin-content.service';
import { AdminNotificationsController } from './admin-notifications.controller';
import { AdminNotificationsService } from './admin-notifications.service';
import { AdminSubscriptionsController } from './admin-subscriptions.controller';
import { AdminSubscriptionsService } from './admin-subscriptions.service';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersService } from './admin-users.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Subscription.name, schema: SubscriptionSchema },
      { name: PaymentEvent.name, schema: PaymentEventSchema },
      { name: Streak.name, schema: StreakSchema },
      { name: AnalyticsDaily.name, schema: AnalyticsDailySchema },
      { name: AiJob.name, schema: AiJobSchema },
      { name: PomodoroSession.name, schema: PomodoroSessionSchema },
      { name: PlannedItem.name, schema: PlannedItemSchema },
      { name: Subject.name, schema: SubjectSchema },
      { name: Notification.name, schema: NotificationSchema },
      { name: AuthSession.name, schema: AuthSessionSchema },
    ]),
    AuthModule,
    UsersModule,
    AiModule,
  ],
  controllers: [
    AdminUsersController,
    AdminSubscriptionsController,
    AdminAnalyticsController,
    AdminNotificationsController,
    AdminContentController,
    AdminAiController,
  ],
  providers: [
    AdminUsersService,
    AdminSubscriptionsService,
    AdminAnalyticsService,
    AdminNotificationsService,
    AdminContentService,
  ],
})
export class AdminModule {}
