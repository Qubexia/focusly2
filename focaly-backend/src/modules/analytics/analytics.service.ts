import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import {
  localDayBounds,
  localDayCount,
  localDayKeysBetween,
  resolveTimezone,
} from '../../common/utils/day.util';
import { PlannedItem, PlannedItemDocument } from '../planned-items/schemas/planned-item.schema';
import {
  PomodoroSession,
  PomodoroSessionDocument,
} from '../pomodoro/schemas/pomodoro-session.schema';
import { StreaksService } from '../streaks/streaks.service';
import { UsersRepository } from '../users/users.repository';

import { AnalyticsRepository } from './analytics.repository';

interface PomodoroTotalsRow {
  totalFocusMinutes?: number;
  totalSessions?: number;
}

interface PomodoroDailyRow {
  _id?: string;
  minutes?: number;
}

interface CountRow {
  total?: number;
}

interface RangeTotals {
  totalFocusMinutes: number;
  totalSessions: number;
  totalTasksCompleted: number;
  activeDays: number;
  dailyFocus: Array<{ date: string; minutes: number }>;
}

@Injectable()
export class AnalyticsService {
  constructor(
    private readonly analyticsRepo: AnalyticsRepository,
    private readonly usersRepo: UsersRepository,
    private readonly streaksService: StreaksService,
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
    @InjectModel(PlannedItem.name)
    private readonly plannedItemModel: Model<PlannedItemDocument>,
  ) {}

  async summary(userId: string, from: Date, to: Date) {
    const tz = await this.timezoneFor(userId);
    const { start, end } = localDayBounds(from, to, tz);
    const totals = await this.rangeTotals(userId, start, end, tz);
    const streak = await this.currentStreak(userId);

    return {
      totalFocusMinutes: totals.totalFocusMinutes,
      totalSessions: totals.totalSessions,
      totalTasksCompleted: totals.totalTasksCompleted,
      // Consecutive study days, straight from the streak record.
      streak,
      // Days inside the selected range that had any focus time.
      activeDays: totals.activeDays,
      dailyFocus: totals.dailyFocus,
      dayCount: localDayCount(start, end, tz),
      timezone: tz,
      range: { from: start.toISOString(), to: end.toISOString() },
    };
  }

  async bySubject(userId: string, from: Date, to: Date) {
    const tz = await this.timezoneFor(userId);
    const { start, end } = localDayBounds(from, to, tz);
    const normalizedUserId = toObjectIdIfPossible(userId);

    return this.pomodoroModel
      .aggregate([
        {
          $match: {
            userId: normalizedUserId,
            status: 'completed',
            startedAt: { $gte: start, $lte: end },
            subjectId: { $ne: null },
            totalFocusMinutes: { $gt: 0 },
          },
        },
        {
          $group: {
            _id: '$subjectId',
            focusMinutes: { $sum: '$totalFocusMinutes' },
          },
        },
        {
          $lookup: {
            from: 'subjects',
            localField: '_id',
            foreignField: '_id',
            as: 'subject',
          },
        },
        {
          $unwind: {
            path: '$subject',
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $project: {
            _id: 0,
            subjectId: { $toString: '$_id' },
            subjectName: { $ifNull: ['$subject.name', 'Unknown'] },
            color: '$subject.color',
            focusMinutes: 1,
          },
        },
        { $sort: { focusMinutes: -1 } },
      ])
      .exec();
  }

  async heatmap(userId: string, year: number) {
    const days = await this.analyticsRepo.getHeatmap(userId, year);
    return { year, days };
  }

  async performance(userId: string, from: Date, to: Date) {
    const tz = await this.timezoneFor(userId);
    const { start, end } = localDayBounds(from, to, tz);
    const dayCount = localDayCount(start, end, tz);

    const [totals, streak] = await Promise.all([
      this.rangeTotals(userId, start, end, tz),
      this.currentStreak(userId),
    ]);

    const completionScore = computeCompletionScore({
      totalFocusMinutes: totals.totalFocusMinutes,
      totalSessions: totals.totalSessions,
      totalTasksCompleted: totals.totalTasksCompleted,
      activeDays: totals.activeDays,
      dayCount,
    });

    return {
      totals: {
        totalFocusMinutes: totals.totalFocusMinutes,
        totalSessions: totals.totalSessions,
        totalTasksCompleted: totals.totalTasksCompleted,
        streak,
        activeDays: totals.activeDays,
        // Legacy aliases kept for older clients.
        totalPlannedItems: totals.totalTasksCompleted,
        streakDays: streak,
      },
      completionScore,
      dayCount,
      timezone: tz,
      range: { from: start.toISOString(), to: end.toISOString() },
    };
  }

  /**
   * One source of truth for every range. Reading the sessions themselves (not
   * the nightly rollup) is what keeps the week, month and year tabs agreeing
   * with each other.
   */
  private async rangeTotals(
    userId: string,
    start: Date,
    end: Date,
    tz: string,
  ): Promise<RangeTotals> {
    const normalizedUserId = toObjectIdIfPossible(userId);
    const zone = resolveTimezone(tz);
    const sessionMatch = {
      userId: normalizedUserId,
      status: 'completed',
      startedAt: { $gte: start, $lte: end },
    };

    const [totalsRows, dailyRows, tasksCompleted] = await Promise.all([
      this.pomodoroModel
        .aggregate<PomodoroTotalsRow>([
          { $match: sessionMatch },
          {
            $group: {
              _id: null,
              totalFocusMinutes: { $sum: '$totalFocusMinutes' },
              totalSessions: { $sum: 1 },
            },
          },
        ])
        .exec(),
      this.pomodoroModel
        .aggregate<PomodoroDailyRow>([
          { $match: sessionMatch },
          {
            $group: {
              _id: {
                $dateToString: { format: '%Y-%m-%d', date: '$startedAt', timezone: zone },
              },
              minutes: { $sum: '$totalFocusMinutes' },
            },
          },
          { $sort: { _id: 1 } },
        ])
        .exec(),
      this.countCompletedTasks(normalizedUserId, start, end, zone),
    ]);

    const totals = totalsRows[0];
    const dailyFocus = dailyRows.map((row) => ({
      date: String(row._id ?? ''),
      minutes: Number(row.minutes ?? 0),
    }));

    return {
      totalFocusMinutes: totals?.totalFocusMinutes ?? 0,
      totalSessions: totals?.totalSessions ?? 0,
      totalTasksCompleted: tasksCompleted,
      activeDays: dailyFocus.filter((day) => day.minutes > 0).length,
      dailyFocus,
    };
  }

  /**
   * One-off items carry a `completedAt` timestamp; recurring items are ticked
   * off per occurrence into `completedDates`, so both have to be counted or
   * every recurring task silently disappears from the stats.
   */
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
        .aggregate<CountRow>([
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

  /** Goes through the service so a streak broken overnight already reads zero. */
  private async currentStreak(userId: string): Promise<number> {
    try {
      const streak = await this.streaksService.getStreak(userId);
      return streak.current;
    } catch {
      return 0;
    }
  }

  private async timezoneFor(userId: string): Promise<string> {
    const user = await this.usersRepo.findActiveById(userId);
    return resolveTimezone(user?.settings?.timezone);
  }
}

function computeCompletionScore(input: {
  totalFocusMinutes: number;
  totalSessions: number;
  totalTasksCompleted: number;
  activeDays: number;
  dayCount: number;
}): number {
  const { totalFocusMinutes, totalSessions, totalTasksCompleted, activeDays, dayCount } = input;
  if (totalFocusMinutes <= 0 && totalSessions <= 0 && totalTasksCompleted <= 0) {
    return 0;
  }

  const focusRatio = Math.min(1, totalFocusMinutes / (25 * dayCount));
  const sessionRatio = Math.min(1, totalSessions / dayCount);
  const consistencyRatio = Math.min(1, activeDays / dayCount);
  const taskRatio =
    totalTasksCompleted > 0 ? Math.min(1, totalTasksCompleted / Math.max(1, dayCount)) : focusRatio;

  const score = 0.45 * focusRatio + 0.25 * sessionRatio + 0.2 * taskRatio + 0.1 * consistencyRatio;

  // Guarantee a visible non-zero score when the user has any activity.
  return Math.min(1, Math.max(score, 0.05));
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}
