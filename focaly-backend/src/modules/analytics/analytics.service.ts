import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import dayjs from 'dayjs';

import { PomodoroSession, PomodoroSessionDocument } from '../pomodoro/schemas/pomodoro-session.schema';

import { AnalyticsRepository } from './analytics.repository';

@Injectable()
export class AnalyticsService {
  constructor(
    private readonly analyticsRepo: AnalyticsRepository,
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
  ) {}

  async summary(userId: string, from: Date, to: Date) {
    const fromDate = dayjs(from).startOf('day').toDate();
    const toDate = dayjs(to).endOf('day').toDate();

    if (dayjs(to).diff(dayjs(from), 'day') <= 7) {
      const [live, streakRows, dailyRows] = await Promise.all([
        this.pomodoroModel
        .aggregate([
          { $match: { userId: userId as any, startedAt: { $gte: fromDate, $lte: toDate } } },
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
          .aggregate([
            {
              $match: {
                userId: userId as any,
                startedAt: { $gte: fromDate, $lte: toDate },
                totalFocusMinutes: { $gt: 0 },
              },
            },
            {
              $group: {
                _id: {
                  $dateToString: { format: '%Y-%m-%d', date: '$startedAt' },
                },
              },
            },
          ])
          .exec(),
        this.pomodoroModel
          .aggregate([
            { $match: { userId: userId as any, startedAt: { $gte: fromDate, $lte: toDate } } },
            {
              $group: {
                _id: {
                  $dateToString: { format: '%Y-%m-%d', date: '$startedAt' },
                },
                minutes: { $sum: '$totalFocusMinutes' },
              },
            },
            { $sort: { _id: 1 } },
          ])
          .exec(),
      ]);

      const s = live[0] ?? { totalFocusMinutes: 0, totalSessions: 0 };
      return {
        totalFocusMinutes: s.totalFocusMinutes ?? 0,
        totalSessions: s.totalSessions ?? 0,
        totalTasksCompleted: 0,
        streak: streakRows.length,
        dailyFocus: dailyRows.map((row) => ({
          date: String(row._id ?? ''),
          minutes: Number(row.minutes ?? 0),
        })),
        range: { from: fromDate.toISOString(), to: toDate.toISOString() },
      };
    }

    const rollup = await this.analyticsRepo.getSummary(userId, fromDate, toDate);
    return {
      totalFocusMinutes: rollup.totalFocusMinutes,
      totalSessions: rollup.totalSessions,
      totalTasksCompleted: rollup.totalPlannedItems,
      streak: rollup.streakDays,
      dailyFocus: [],
      range: { from: fromDate.toISOString(), to: toDate.toISOString() },
    };
  }

  async bySubject(userId: string, from: Date, to: Date) {
    const subjects = await this.analyticsRepo.getBySubject(userId, from, to);
    return subjects;
  }

  async heatmap(userId: string, year: number) {
    const days = await this.analyticsRepo.getHeatmap(userId, year);
    return { year, days };
  }

  async performance(userId: string, from: Date, to: Date) {
    const fromDate = dayjs(from).startOf('day').toDate();
    const toDate = dayjs(to).endOf('day').toDate();

    const rollup = await this.analyticsRepo.getSummary(userId, fromDate, toDate);
    return {
      totals: rollup,
      range: { from: fromDate.toISOString(), to: toDate.toISOString() },
    };
  }
}
