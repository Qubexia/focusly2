import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { AiJob, AiJobDocument } from '../ai/schemas/ai-job.schema';
import { PlannedItem, PlannedItemDocument } from '../planned-items/schemas/planned-item.schema';
import {
  PomodoroSession,
  PomodoroSessionDocument,
} from '../pomodoro/schemas/pomodoro-session.schema';
import { Subscription, SubscriptionDocument } from '../subscription/schemas/subscription.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

import { SignupsQueryDto } from './dto/admin-analytics.dto';

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class AdminAnalyticsService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Subscription.name) private readonly subscriptionModel: Model<SubscriptionDocument>,
    @InjectModel(AiJob.name) private readonly aiJobModel: Model<AiJobDocument>,
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
    @InjectModel(PlannedItem.name) private readonly plannedItemModel: Model<PlannedItemDocument>,
  ) {}

  async overview(): Promise<unknown> {
    const now = new Date();
    const dayAgo = new Date(now.getTime() - DAY_MS);
    const monthAgo = new Date(now.getTime() - 30 * DAY_MS);

    const [
      totalUsers,
      premiumUsers,
      bannedUsers,
      newUsers30d,
      dau,
      mau,
      activeSubscriptions,
      aiAgg,
      pomodoroAgg,
      tasksCompleted,
    ] = await Promise.all([
      this.userModel.countDocuments({ isDeleted: false }).exec(),
      this.userModel.countDocuments({ isDeleted: false, plan: 'premium' }).exec(),
      this.userModel.countDocuments({ isBanned: true }).exec(),
      this.userModel.countDocuments({ isDeleted: false, createdAt: { $gte: monthAgo } }).exec(),
      this.userModel.countDocuments({ lastActiveAt: { $gte: dayAgo } }).exec(),
      this.userModel.countDocuments({ lastActiveAt: { $gte: monthAgo } }).exec(),
      this.subscriptionModel.countDocuments({ status: { $in: ['active', 'trialing'] } }).exec(),
      this.aiJobModel.aggregate<{ jobs: number; tokensIn: number; tokensOut: number }>([
        {
          $group: {
            _id: null,
            jobs: { $sum: 1 },
            tokensIn: { $sum: { $ifNull: ['$tokensIn', 0] } },
            tokensOut: { $sum: { $ifNull: ['$tokensOut', 0] } },
          },
        },
      ]),
      this.pomodoroModel.aggregate<{ sessions: number; focusMinutes: number }>([
        {
          $group: {
            _id: null,
            sessions: { $sum: 1 },
            focusMinutes: { $sum: { $ifNull: ['$totalFocusMinutes', 0] } },
          },
        },
      ]),
      this.plannedItemModel.countDocuments({ completed: true }).exec(),
    ]);

    const ai = aiAgg[0] ?? { jobs: 0, tokensIn: 0, tokensOut: 0 };
    const pomodoro = pomodoroAgg[0] ?? { sessions: 0, focusMinutes: 0 };

    return {
      users: {
        total: totalUsers,
        premium: premiumUsers,
        free: totalUsers - premiumUsers,
        banned: bannedUsers,
        newLast30Days: newUsers30d,
        dau,
        mau,
      },
      subscriptions: { active: activeSubscriptions },
      ai: {
        jobs: ai.jobs,
        tokensIn: ai.tokensIn,
        tokensOut: ai.tokensOut,
        totalTokens: ai.tokensIn + ai.tokensOut,
      },
      engagement: {
        pomodoroSessions: pomodoro.sessions,
        focusMinutes: pomodoro.focusMinutes,
        tasksCompleted,
      },
    };
  }

  async signups(query: SignupsQueryDto): Promise<unknown> {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from ? new Date(query.from) : new Date(to.getTime() - 30 * DAY_MS);

    const rows = await this.userModel.aggregate<{ _id: string; count: number }>([
      { $match: { createdAt: { $gte: from, $lte: to } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return {
      from: from.toISOString(),
      to: to.toISOString(),
      series: rows.map((r) => ({ date: r._id, count: r.count })),
    };
  }
}
