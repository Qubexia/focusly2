import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';

import { ERROR_CODES } from '../../common/dto/api-response';
import { PaymentEvent, PaymentEventDocument } from '../subscription/schemas/payment-event.schema';
import { Subscription, SubscriptionDocument } from '../subscription/schemas/subscription.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

import {
  ExtendSubscriptionDto,
  ListSubscriptionsQueryDto,
  RevenueQueryDto,
} from './dto/admin-subscriptions.dto';
import { paginated, Paginated, resolvePaging } from './dto/pagination.dto';

@Injectable()
export class AdminSubscriptionsService {
  constructor(
    @InjectModel(Subscription.name) private readonly subscriptionModel: Model<SubscriptionDocument>,
    @InjectModel(PaymentEvent.name) private readonly paymentEventModel: Model<PaymentEventDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
  ) {}

  async list(query: ListSubscriptionsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<SubscriptionDocument> = {};
    if (query.status) filter.status = query.status;
    if (query.provider) filter.provider = query.provider;

    const [items, total] = await Promise.all([
      this.subscriptionModel.aggregate([
        { $match: filter },
        { $sort: { updatedAt: -1 } },
        { $skip: skip },
        { $limit: limit },
        {
          $lookup: {
            from: 'users',
            localField: 'userId',
            foreignField: '_id',
            as: 'user',
          },
        },
        { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            provider: 1,
            status: 1,
            currentPeriodEnd: 1,
            priceId: 1,
            lastEventAt: 1,
            createdAt: 1,
            updatedAt: 1,
            userId: 1,
            'user.email': 1,
            'user.name': 1,
            'user.plan': 1,
            'user.premiumUntil': 1,
          },
        },
      ]),
      this.subscriptionModel.countDocuments(filter).exec(),
    ]);

    return paginated(items, total, page, limit);
  }

  async getByUserId(userId: string): Promise<unknown> {
    const [subscription, user, events] = await Promise.all([
      this.subscriptionModel.findOne({ userId }).lean().exec(),
      this.userModel.findById(userId).select('email name plan premiumUntil').lean().exec(),
      this.paymentEventModel.find({ userId }).sort({ createdAt: -1 }).limit(50).lean().exec(),
    ]);

    if (!user) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }

    return { user, subscription: subscription ?? null, events };
  }

  async extend(userId: string, dto: ExtendSubscriptionDto): Promise<unknown> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }

    const base =
      user.premiumUntil && user.premiumUntil > new Date() ? user.premiumUntil : new Date();
    const premiumUntil = new Date(base.getTime() + dto.days * 24 * 60 * 60 * 1000);

    user.plan = 'premium';
    user.premiumUntil = premiumUntil;
    await user.save();

    await this.subscriptionModel
      .updateOne(
        { userId },
        { $set: { status: 'active', currentPeriodEnd: premiumUntil, lastEventAt: new Date() } },
      )
      .exec();

    return { plan: user.plan, premiumUntil };
  }

  async cancel(userId: string): Promise<unknown> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'User was not found.' });
    }

    user.plan = 'free';
    user.premiumUntil = null;
    await user.save();

    await this.subscriptionModel
      .updateOne({ userId }, { $set: { status: 'canceled', lastEventAt: new Date() } })
      .exec();

    return { plan: user.plan, premiumUntil: null };
  }

  async revenueSummary(query: RevenueQueryDto): Promise<unknown> {
    const range: FilterQuery<PaymentEventDocument> = {};
    if (query.from || query.to) {
      range.createdAt = {};
      if (query.from) (range.createdAt as Record<string, Date>).$gte = new Date(query.from);
      if (query.to) (range.createdAt as Record<string, Date>).$lte = new Date(query.to);
    }

    type CountRow = { _id: string | null; count: number };
    const [byStatus, byProvider, paymentsByProvider, activeCount] = await Promise.all([
      this.subscriptionModel.aggregate<CountRow>([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      this.subscriptionModel.aggregate<CountRow>([
        { $group: { _id: '$provider', count: { $sum: 1 } } },
      ]),
      this.paymentEventModel.aggregate<CountRow>([
        { $match: { ...range, outcome: 'applied' } },
        { $group: { _id: '$provider', count: { $sum: 1 } } },
      ]),
      this.subscriptionModel.countDocuments({ status: { $in: ['active', 'trialing'] } }).exec(),
    ]);

    return {
      activeSubscriptions: activeCount,
      subscriptionsByStatus: toMap(byStatus),
      subscriptionsByProvider: toMap(byProvider),
      appliedPaymentsByProvider: toMap(paymentsByProvider),
    };
  }
}

function toMap(rows: Array<{ _id: string | null; count: number }>): Record<string, number> {
  return rows.reduce<Record<string, number>>((acc, row) => {
    acc[row._id ?? 'unknown'] = row.count;
    return acc;
  }, {});
}
