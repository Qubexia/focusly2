import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import dayjs from 'dayjs';
import { Model, Types } from 'mongoose';

import {
  PomodoroSession,
  PomodoroSessionDocument,
} from '../pomodoro/schemas/pomodoro-session.schema';

import { AnalyticsRepository } from './analytics.repository';

interface PomodoroTotalsRow {
  totalFocusMinutes?: number;
  totalSessions?: number;
}

interface PomodoroDailyRow {
  _id?: string;
  minutes?: number;
}

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
    const normalizedUserId = toObjectIdIfPossible(userId);

    if (dayjs(to).diff(dayjs(from), 'day') <= 7) {
      const [live, streakRows, dailyRows] = await Promise.all([
        this.pomodoroModel
          .aggregate<PomodoroTotalsRow>([
            { $match: { userId: normalizedUserId, startedAt: { $gte: fromDate, $lte: toDate } } },
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
                userId: normalizedUserId,
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
          .aggregate<PomodoroDailyRow>([
            { $match: { userId: normalizedUserId, startedAt: { $gte: fromDate, $lte: toDate } } },
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

      const s = live[0];
      return {
        totalFocusMinutes: s?.totalFocusMinutes ?? 0,
        totalSessions: s?.totalSessions ?? 0,
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
    const dailyRows = await this.analyticsRepo.getDailySeries(userId, fromDate, toDate);
    return {
      totalFocusMinutes: rollup.totalFocusMinutes,
      totalSessions: rollup.totalSessions,
      totalTasksCompleted: rollup.totalPlannedItems,
      streak: rollup.streakDays,
      dailyFocus: dailyRows,
      range: { from: fromDate.toISOString(), to: toDate.toISOString() },
    };
  }

  async bySubject(userId: string, from: Date, to: Date) {
    const fromDate = dayjs(from).startOf('day').toDate();
    const toDate = dayjs(to).endOf('day').toDate();
    const normalizedUserId = toObjectIdIfPossible(userId);

    return this.pomodoroModel
      .aggregate([
        {
          $match: {
            userId: normalizedUserId,
            startedAt: { $gte: fromDate, $lte: toDate },
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
    const fromDate = dayjs(from).startOf('day').toDate();
    const toDate = dayjs(to).endOf('day').toDate();
    const normalizedUserId = toObjectIdIfPossible(userId);

    const [rollup, live] = await Promise.all([
      this.analyticsRepo.getSummary(userId, fromDate, toDate),
      this.pomodoroModel
        .aggregate<PomodoroTotalsRow>([
          {
            $match: {
              userId: normalizedUserId,
              startedAt: { $gte: fromDate, $lte: toDate },
            },
          },
          {
            $group: {
              _id: null,
              totalFocusMinutes: { $sum: '$totalFocusMinutes' },
              totalSessions: { $sum: 1 },
            },
          },
        ])
        .exec(),
    ]);

    const liveTotals = live[0];
    const liveFocusMinutes = liveTotals?.totalFocusMinutes ?? 0;
    const liveSessions = liveTotals?.totalSessions ?? 0;
    return {
      totals: {
        ...rollup,
        totalFocusMinutes: Math.max(rollup.totalFocusMinutes, liveFocusMinutes),
        totalSessions: Math.max(rollup.totalSessions, liveSessions),
      },
      range: { from: fromDate.toISOString(), to: toDate.toISOString() },
    };
  }
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}
