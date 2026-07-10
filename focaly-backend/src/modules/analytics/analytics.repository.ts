import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import dayjs from 'dayjs';
import { Model, Types } from 'mongoose';

import { AnalyticsDaily, AnalyticsDailyDocument } from './schemas/analytics-daily.schema';

export interface AnalyticsSummary {
  totalFocusMinutes: number;
  totalCompletedCycles: number;
  totalPlannedItems: number;
  totalSessions: number;
  streakDays: number;
}

interface AnalyticsAggregateRow {
  totalFocusMinutes?: number;
  totalCompletedCycles?: number;
  totalPlannedItems?: number;
  totalSessions?: number;
}

@Injectable()
export class AnalyticsRepository {
  constructor(
    @InjectModel(AnalyticsDaily.name)
    private readonly model: Model<AnalyticsDailyDocument>,
  ) {}

  async getSummary(userId: string, from: Date, to: Date): Promise<AnalyticsSummary> {
    const normalizedUserId = toObjectIdIfPossible(userId);

    const results = await this.model
      .aggregate<AnalyticsAggregateRow>([
        { $match: { userId: normalizedUserId, date: { $gte: from, $lte: to } } },
        {
          $group: {
            _id: null,
            totalFocusMinutes: { $sum: '$focusMinutes' },
            totalCompletedCycles: { $sum: '$completedCycles' },
            totalPlannedItems: { $sum: '$plannedItemsCompleted' },
            totalSessions: { $sum: '$sessionsCount' },
          },
        },
      ])
      .exec();

    if (results.length === 0) {
      return {
        totalFocusMinutes: 0,
        totalCompletedCycles: 0,
        totalPlannedItems: 0,
        totalSessions: 0,
        streakDays: 0,
      };
    }

    const daysActive = await this.model
      .countDocuments({
        userId: normalizedUserId,
        date: { $gte: from, $lte: to },
        focusMinutes: { $gt: 0 },
      })
      .exec();

    const row = results[0];
    return {
      totalFocusMinutes: row?.totalFocusMinutes ?? 0,
      totalCompletedCycles: row?.totalCompletedCycles ?? 0,
      totalPlannedItems: row?.totalPlannedItems ?? 0,
      totalSessions: row?.totalSessions ?? 0,
      streakDays: daysActive,
    };
  }

  getBySubject(
    _userId: string,
    _from: Date,
    _to: Date,
  ): Promise<Array<{ subjectId: string; focusMinutes: number }>> {
    return Promise.resolve([]);
  }

  async getHeatmap(
    userId: string,
    year: number,
  ): Promise<Array<{ date: string; focusMinutes: number }>> {
    const start = dayjs().year(year).startOf('year').toDate();
    const end = dayjs().year(year).endOf('year').toDate();
    const normalizedUserId = toObjectIdIfPossible(userId);

    return this.model
      .find({ userId: normalizedUserId, date: { $gte: start, $lte: end } })
      .sort({ date: 1 })
      .lean()
      .exec()
      .then((rows) =>
        rows.map((r) => ({
          date: dayjs(r.date).format('YYYY-MM-DD'),
          focusMinutes: r.focusMinutes,
        })),
      );
  }

  async getDailySeries(
    userId: string,
    from: Date,
    to: Date,
  ): Promise<Array<{ date: string; minutes: number }>> {
    const normalizedUserId = toObjectIdIfPossible(userId);

    const rows = await this.model
      .find({
        userId: normalizedUserId,
        date: { $gte: from, $lte: to },
      })
      .sort({ date: 1 })
      .lean()
      .exec();

    return rows.map((row) => ({
      date: dayjs(row.date).format('YYYY-MM-DD'),
      minutes: row.focusMinutes ?? 0,
    }));
  }

  async upsertDay(
    userId: string,
    date: Date,
    data: {
      focusMinutes: number;
      completedCycles: number;
      plannedItemsCompleted: number;
      sessionsCount: number;
    },
  ): Promise<void> {
    const dateStart = dayjs(date).startOf('day').toDate();
    const normalizedUserId = toObjectIdIfPossible(userId);

    await this.model
      .updateOne(
        { userId: normalizedUserId, date: dateStart },
        { $set: { userId: normalizedUserId, date: dateStart }, $inc: data },
        { upsert: true },
      )
      .exec();
  }
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}
