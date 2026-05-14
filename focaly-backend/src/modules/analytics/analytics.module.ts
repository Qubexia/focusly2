import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { PomodoroSession, PomodoroSessionSchema } from '../pomodoro/schemas/pomodoro-session.schema';

import { AnalyticsController } from './analytics.controller';
import { AnalyticsRepository } from './analytics.repository';
import { AnalyticsRollupService } from './analytics-rollup.service';
import { AnalyticsService } from './analytics.service';
import { AnalyticsDaily, AnalyticsDailySchema } from './schemas/analytics-daily.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AnalyticsDaily.name, schema: AnalyticsDailySchema },
      { name: PomodoroSession.name, schema: PomodoroSessionSchema },
    ]),
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService, AnalyticsRepository, AnalyticsRollupService],
  exports: [AnalyticsService, AnalyticsRepository],
})
export class AnalyticsModule {}
