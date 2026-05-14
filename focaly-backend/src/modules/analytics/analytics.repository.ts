import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import dayjs from 'dayjs';

import { AnalyticsDaily, AnalyticsDailyDocument } from './schemas/analytics-daily.schema';

export interface AnalyticsSummary {
  totalFocusMinutes: number;
  totalCompletedCycles: number;
  totalPlannedItems: number;
  totalSessions: number;
  streakDays: number;
}

@Injectable()
export class AnalyticsRepository {
  constructor(
    @InjectModel(AnalyticsDaily.name)
    private readonly model: Model<AnalyticsDailyDocument>,
  ) {}

  async getSummary(userId: string, from: Date, to: Date): Promise<AnalyticsSummary> {
    const results = await this.model
      .aggregate([
        { $match: { userId: userId as any, date: { $gte: from, $lte: to } } },
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
      return { totalFocusMinutes: 0, totalCompletedCycles: 0, totalPlannedItems: 0, totalSessions: 0, streakDays: 0 };
    }

    const daysActive = await this.model
      .countDocuments({ userId: userId as any, date: { $gte: from, $lte: to }, focusMinutes: { $gt: 0 } })
      .exec();

    return {
      totalFocusMinutes: results[0]!.totalFocusMinutes ?? 0,
      totalCompletedCycles: results[0]!.totalCompletedCycles ?? 0,
      totalPlannedItems: results[0]!.totalPlannedItems ?? 0,
      totalSessions: results[0]!.totalSessions ?? 0,
      streakDays: daysActive,
    };
  }

  async getBySubject(userId: string, from: Date, to: Date): Promise<Array<{ subjectId: string; focusMinutes: number }>> {
    return [];
  }

  async getHeatmap(userId: string, year: number): Promise<Array<{ date: string; focusMinutes: number }>> {
    const start = dayjs().year(year).startOf('year').toDate();
    const end = dayjs().year(year).endOf('year').toDate();

    return this.model
      .find({ userId: userId as any, date: { $gte: start, $lte: end } })
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

  async upsertDay(
    userId: string,
    date: Date,
    data: { focusMinutes: number; completedCycles: number; plannedItemsCompleted: number; sessionsCount: number },
  ): Promise<void> {
    const dateStart = dayjs(date).startOf('day').toDate();
    await this.model
      .updateOne(
        { userId: userId as any, date: dateStart },
        { $set: { userId: userId as any, date: dateStart }, $inc: data },
        { upsert: true },
      )
      .exec();
  }
}
