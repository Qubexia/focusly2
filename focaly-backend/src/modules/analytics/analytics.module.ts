import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { PlannedItem, PlannedItemSchema } from '../planned-items/schemas/planned-item.schema';
import {
  PomodoroSession,
  PomodoroSessionSchema,
} from '../pomodoro/schemas/pomodoro-session.schema';

import { AnalyticsRollupService } from './analytics-rollup.service';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsRepository } from './analytics.repository';
import { AnalyticsService } from './analytics.service';
import { PomodoroCompletedAnalyticsHandler } from './handlers/pomodoro-completed-analytics.handler';
import { AnalyticsDaily, AnalyticsDailySchema } from './schemas/analytics-daily.schema';

@Module({
  imports: [
    CqrsModule,
    MongooseModule.forFeature([
      { name: AnalyticsDaily.name, schema: AnalyticsDailySchema },
      { name: PomodoroSession.name, schema: PomodoroSessionSchema },
      { name: PlannedItem.name, schema: PlannedItemSchema },
    ]),
  ],
  controllers: [AnalyticsController],
  providers: [
    AnalyticsService,
    AnalyticsRepository,
    AnalyticsRollupService,
    PomodoroCompletedAnalyticsHandler,
  ],
  exports: [AnalyticsService, AnalyticsRepository],
})
export class AnalyticsModule {}
