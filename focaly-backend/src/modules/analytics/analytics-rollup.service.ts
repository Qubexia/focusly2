import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Cron } from '@nestjs/schedule';
import { Model, Types } from 'mongoose';

import {
  dayjs,
  localDayBounds,
  localDayKeysBetween,
  resolveTimezone,
  yesterdayKey,
} from '../../common/utils/day.util';
import { PlannedItem, PlannedItemDocument } from '../planned-items/schemas/planned-item.schema';
import {
  PomodoroSession,
  PomodoroSessionDocument,
} from '../pomodoro/schemas/pomodoro-session.schema';
import { UsersRepository } from '../users/users.repository';

import { AnalyticsRepository } from './analytics.repository';

/** Wide enough to cover "yesterday" in every timezone on earth. */
const CANDIDATE_WINDOW_HOURS = 60;

@Injectable()
export class AnalyticsRollupService {
  private readonly logger = new Logger(AnalyticsRollupService.name);

  constructor(
    private readonly analyticsRepo: AnalyticsRepository,
    private readonly usersRepo: UsersRepository,
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
    @InjectModel(PlannedItem.name)
    private readonly plannedItemModel: Model<PlannedItemDocument>,
  ) {}

  /**
   * Recomputes each active user's previous local day from the raw sessions.
   * It overwrites the day rather than adding to it, so running twice — or
   * running after the live handler already wrote the same day — is safe.
   */
  @Cron('0 1 * * *')
  async rollupYesterday(): Promise<void> {
    this.logger.log('Running daily analytics rollup...');

    const userIds = await this.findRecentlyActiveUsers();
    let rolledUp = 0;

    for (const userId of userIds) {
      try {
        await this.rollupUserDay(userId);
        rolledUp++;
      } catch (error) {
        this.logger.error(`Rollup failed for user ${userId}: ${String(error)}`);
      }
    }

    this.logger.log(`Rolled up ${rolledUp}/${userIds.length} users' analytics.`);
  }

  private async rollupUserDay(userId: string): Promise<void> {
    const user = await this.usersRepo.findActiveById(userId);
    if (!user) return;

    const tz = resolveTimezone(user.settings?.timezone);
    const dayKey = yesterdayKey(tz);
    const { start, end } = localDayBounds(dayKey, dayKey, tz);
    const normalizedUserId = toObjectIdIfPossible(userId);

    const [totals, plannedItemsCompleted] = await Promise.all([
      this.pomodoroModel
        .aggregate<{
          focusMinutes?: number;
          completedCycles?: number;
          sessionsCount?: number;
        }>([
          {
            $match: {
              userId: normalizedUserId,
              status: 'completed',
              startedAt: { $gte: start, $lte: end },
            },
          },
          {
            $group: {
              _id: null,
              focusMinutes: { $sum: '$totalFocusMinutes' },
              completedCycles: { $sum: '$completedCycles' },
              sessionsCount: { $sum: 1 },
            },
          },
        ])
        .exec(),
      this.countCompletedTasks(normalizedUserId, start, end, tz),
    ]);

    const row = totals[0];
    const focusMinutes = row?.focusMinutes ?? 0;
    const sessionsCount = row?.sessionsCount ?? 0;
    if (focusMinutes === 0 && sessionsCount === 0 && plannedItemsCompleted === 0) return;

    // The rollup row is keyed by the UTC-normalised local day so it lines up
    // with the day the live handler writes.
    await this.analyticsRepo.setDay(userId, dayjs(`${dayKey}T00:00:00Z`).toDate(), {
      focusMinutes,
      completedCycles: row?.completedCycles ?? 0,
      plannedItemsCompleted,
      sessionsCount,
    });
  }

  private async countCompletedTasks(
    userId: Types.ObjectId | string,
    start: Date,
    end: Date,
    tz: string,
  ): Promise<number> {
    const dayKeys = localDayKeysBetween(start, end, tz);

    const [oneOff, recurringRows] = await Promise.all([
      this.plannedItemModel
        .countDocuments({
          userId,
          recurrence: 'once',
          completed: true,
          completedAt: { $gte: start, $lte: end },
        })
        .exec(),
      this.plannedItemModel
        .aggregate<{ total?: number }>([
          {
            $match: {
              userId,
              recurrence: { $ne: 'once' },
              completedDates: { $in: dayKeys },
            },
          },
          {
            $project: {
              hits: { $size: { $setIntersection: ['$completedDates', dayKeys] } },
            },
          },
          { $group: { _id: null, total: { $sum: '$hits' } } },
        ])
        .exec(),
    ]);

    return oneOff + Number(recurringRows[0]?.total ?? 0);
  }

  private async findRecentlyActiveUsers(): Promise<string[]> {
    const since = dayjs().subtract(CANDIDATE_WINDOW_HOURS, 'hour').toDate();
    const recentDayKeys = localDayKeysBetween(since, new Date(), 'UTC');

    const [sessionUsers, taskUsers, recurringUsers] = await Promise.all([
      this.pomodoroModel.distinct('userId', {
        status: 'completed',
        startedAt: { $gte: since },
      }),
      this.plannedItemModel.distinct('userId', {
        completed: true,
        completedAt: { $gte: since },
      }),
      this.plannedItemModel.distinct('userId', {
        completedDates: { $in: recentDayKeys },
      }),
    ]);

    const ids = new Set<string>();
    for (const list of [sessionUsers, taskUsers, recurringUsers]) {
      for (const id of list) ids.add(String(id));
    }
    return [...ids];
  }
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}
