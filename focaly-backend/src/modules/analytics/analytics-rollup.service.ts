import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Cron } from '@nestjs/schedule';
import { Model } from 'mongoose';
import dayjs from 'dayjs';

import { PomodoroSession, PomodoroSessionDocument } from '../pomodoro/schemas/pomodoro-session.schema';

import { AnalyticsRepository } from './analytics.repository';

@Injectable()
export class AnalyticsRollupService {
  private readonly logger = new Logger(AnalyticsRollupService.name);

  constructor(
    private readonly analyticsRepo: AnalyticsRepository,
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
  ) {}

  @Cron('0 1 * * *')
  async rollupYesterday(): Promise<void> {
    this.logger.log('Running daily analytics rollup...');

    const yesterday = dayjs().subtract(1, 'day');
    const dayStart = yesterday.startOf('day').toDate();
    const dayEnd = yesterday.endOf('day').toDate();

    const sessions = await this.pomodoroModel
      .aggregate([
        {
          $match: {
            startedAt: { $gte: dayStart, $lte: dayEnd },
          },
        },
        {
          $group: {
            _id: '$userId',
            totalFocusMinutes: { $sum: '$totalFocusMinutes' },
            completedCycles: { $sum: '$completedCycles' },
            sessionsCount: { $sum: 1 },
          },
        },
      ])
      .exec();

    for (const row of sessions) {
      await this.analyticsRepo.upsertDay(row._id.toString(), dayStart, {
        focusMinutes: row.totalFocusMinutes ?? 0,
        completedCycles: row.completedCycles ?? 0,
        plannedItemsCompleted: 0,
        sessionsCount: row.sessionsCount ?? 0,
      });
    }

    this.logger.log(`Rolled up ${sessions.length} users' analytics for ${yesterday.format('YYYY-MM-DD')}`);
  }
}
