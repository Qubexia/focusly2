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
      const live = await this.pomodoroModel
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
        .exec();

      const s = live[0] ?? { totalFocusMinutes: 0, totalSessions: 0 };
      return {
        totals: { minutes: s.totalFocusMinutes, sessions: s.totalSessions },
        range: { from: from.toISOString(), to: to.toISOString() },
      };
    }

    const rollup = await this.analyticsRepo.getSummary(userId, fromDate, toDate);
    return {
      totals: { minutes: rollup.totalFocusMinutes, sessions: rollup.totalSessions },
      range: { from: from.toISOString(), to: to.toISOString() },
    };
  }

  async bySubject(userId: string, from: Date, to: Date) {
    const subjects = await this.analyticsRepo.getBySubject(userId, from, to);
    return { subjects, range: { from: from.toISOString(), to: to.toISOString() } };
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
      range: { from: from.toISOString(), to: to.toISOString() },
    };
  }
}
