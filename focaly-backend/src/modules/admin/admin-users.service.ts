import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';

import { ERROR_CODES } from '../../common/dto/api-response';
import {
  AnalyticsDaily,
  AnalyticsDailyDocument,
} from '../analytics/schemas/analytics-daily.schema';
import { AuthSessionsRepository } from '../auth/auth-sessions.repository';
import { Streak, StreakDocument } from '../streaks/schemas/streak.schema';
import { Subscription, SubscriptionDocument } from '../subscription/schemas/subscription.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { UsersRepository } from '../users/users.repository';

import { ListUsersQueryDto, UpdateUserAdminDto } from './dto/admin-users.dto';
import { paginated, Paginated, resolvePaging } from './dto/pagination.dto';

const PUBLIC_FIELDS = '-passwordHash';

@Injectable()
export class AdminUsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Subscription.name) private readonly subscriptionModel: Model<SubscriptionDocument>,
    @InjectModel(Streak.name) private readonly streakModel: Model<StreakDocument>,
    @InjectModel(AnalyticsDaily.name)
    private readonly analyticsModel: Model<AnalyticsDailyDocument>,
    private readonly usersRepository: UsersRepository,
    private readonly authSessionsRepository: AuthSessionsRepository,
  ) {}

  async list(query: ListUsersQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<UserDocument> = {};

    if (query.q) {
      const rx = new RegExp(escapeRegExp(query.q), 'i');
      filter.$or = [{ email: rx }, { name: rx }];
    }
    if (query.plan) filter.plan = query.plan;
    if (query.role) filter.role = query.role;

    switch (query.status) {
      case 'banned':
        filter.isBanned = true;
        break;
      case 'deleted':
        filter.isDeleted = true;
        break;
      case 'active':
        filter.isDeleted = false;
        filter.isBanned = false;
        break;
      default:
        filter.isDeleted = false;
    }

    const [items, total] = await Promise.all([
      this.userModel
        .find(filter)
        .select(PUBLIC_FIELDS)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.userModel.countDocuments(filter).exec(),
    ]);

    return paginated(items, total, page, limit);
  }

  async getById(id: string): Promise<unknown> {
    const user = await this.userModel.findById(id).select(PUBLIC_FIELDS).lean().exec();
    if (!user) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }

    const [subscription, streak, sessions, activity] = await Promise.all([
      this.subscriptionModel.findOne({ userId: id }).lean().exec(),
      this.streakModel.findOne({ userId: id }).lean().exec(),
      this.authSessionsRepository.findActiveByUserId(id),
      this.analyticsModel
        .aggregate<{
          focusMinutes: number;
          completedCycles: number;
          plannedItemsCompleted: number;
        }>([
          { $match: { userId: toObjectId(id) } },
          {
            $group: {
              _id: null,
              focusMinutes: { $sum: '$focusMinutes' },
              completedCycles: { $sum: '$completedCycles' },
              plannedItemsCompleted: { $sum: '$plannedItemsCompleted' },
            },
          },
        ])
        .exec(),
    ]);

    return {
      ...user,
      subscription: subscription ?? null,
      streak: streak ?? null,
      activeSessions: sessions.length,
      activity: activity[0] ?? {
        focusMinutes: 0,
        completedCycles: 0,
        plannedItemsCompleted: 0,
      },
    };
  }

  async update(id: string, dto: UpdateUserAdminDto): Promise<unknown> {
    const update: Record<string, unknown> = {};
    if (dto.name !== undefined) update.name = dto.name;
    if (dto.role !== undefined) update.role = dto.role;
    if (dto.plan !== undefined) update.plan = dto.plan;
    if (dto.emailVerified !== undefined) update.emailVerified = dto.emailVerified;
    if (dto.premiumUntil !== undefined) {
      update.premiumUntil = dto.premiumUntil === null ? null : new Date(dto.premiumUntil);
    }

    const updated = await this.userModel
      .findByIdAndUpdate(id, { $set: update }, { new: true, runValidators: true })
      .select(PUBLIC_FIELDS)
      .lean()
      .exec();

    if (!updated) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }
    return updated;
  }

  async setBanned(id: string, banned: boolean): Promise<unknown> {
    const updated = await this.userModel
      .findByIdAndUpdate(
        id,
        { $set: { isBanned: banned, bannedAt: banned ? new Date() : null } },
        { new: true, runValidators: true },
      )
      .select(PUBLIC_FIELDS)
      .lean()
      .exec();

    if (!updated) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }

    // A ban must take effect immediately: drop all refresh sessions.
    if (banned) {
      await this.authSessionsRepository.revokeAllByUserId(id);
    }
    return updated;
  }

  async remove(id: string): Promise<void> {
    const user = await this.userModel.findById(id).select('_id').lean().exec();
    if (!user) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }
    await this.usersRepository.markDeleted(id);
    await this.authSessionsRepository.revokeAllByUserId(id);
  }

  listSessions(id: string): Promise<unknown> {
    return this.authSessionsRepository.findActiveByUserId(id);
  }

  async revokeSession(id: string, sessionId: string): Promise<void> {
    const revoked = await this.authSessionsRepository.revokeById(id, sessionId);
    if (!revoked) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Session was not found.',
      });
    }
  }
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toObjectId(id: string): Types.ObjectId {
  return new Types.ObjectId(id);
}
