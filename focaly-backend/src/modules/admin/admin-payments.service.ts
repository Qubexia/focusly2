import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';

import { ERROR_CODES } from '../../common/dto/api-response';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { PaymentEvent, PaymentEventDocument } from '../subscription/schemas/payment-event.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

import { ListPaymentsQueryDto, RevenueReportQueryDto } from './dto/admin-payments.dto';
import { paginated, Paginated, resolvePaging } from './dto/pagination.dto';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Only settled money counts as revenue — retries and failures must not inflate it. */
const REVENUE_MATCH = { outcome: 'applied', amountCents: { $gt: 0 } } as const;

export interface RevenueBucket {
  period: string;
  grossCents: number;
  payments: number;
}

@Injectable()
export class AdminPaymentsService {
  constructor(
    @InjectModel(PaymentEvent.name) private readonly paymentModel: Model<PaymentEventDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly platformSettings: PlatformSettingsService,
  ) {}

  async list(query: ListPaymentsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter = await this.buildFilter(query);

    const [items, total] = await Promise.all([
      this.paymentModel.aggregate([
        { $match: filter },
        { $sort: { createdAt: -1 } },
        { $skip: skip },
        { $limit: limit },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'user' } },
        { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            provider: 1,
            eventId: 1,
            providerTxId: 1,
            amountCents: 1,
            currency: 1,
            plan: 1,
            outcome: 1,
            error: 1,
            processedAt: 1,
            createdAt: 1,
            userId: 1,
            'user.email': 1,
            'user.name': 1,
            'user.plan': 1,
          },
        },
      ]),
      this.paymentModel.countDocuments(filter).exec(),
    ]);

    return paginated(items, total, page, limit);
  }

  /** One payment with its raw provider payload, for reconciliation/debugging. */
  async getById(id: string): Promise<unknown> {
    if (!Types.ObjectId.isValid(id)) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'Payment not found.' });
    }

    const event = await this.paymentModel.findById(id).lean().exec();
    if (!event) {
      throw new NotFoundException({ code: ERROR_CODES.NOT_FOUND, message: 'Payment not found.' });
    }

    const user = event.userId
      ? await this.userModel.findById(event.userId).select('email name plan premiumUntil').lean().exec()
      : null;

    return { ...event, user };
  }

  /**
   * Money actually collected in the window. Amounts are grouped by currency —
   * summing mixed currencies into one number would be a lie, not a total.
   */
  async revenue(query: RevenueReportQueryDto): Promise<unknown> {
    const to = query.to ? new Date(query.to) : new Date();
    const from = query.from ? new Date(query.from) : new Date(to.getTime() - 30 * DAY_MS);
    const interval = query.interval ?? 'day';
    const range = { ...REVENUE_MATCH, createdAt: { $gte: from, $lte: to } };

    type GroupRow = { _id: string | null; grossCents: number; payments: number };
    const group = { grossCents: { $sum: '$amountCents' }, payments: { $sum: 1 } };

    const [byCurrency, byProvider, byPlan, series, allTime] = await Promise.all([
      this.paymentModel.aggregate<GroupRow>([
        { $match: range },
        { $group: { _id: '$currency', ...group } },
        { $sort: { grossCents: -1 } },
      ]),
      this.paymentModel.aggregate<GroupRow>([
        { $match: range },
        { $group: { _id: '$provider', ...group } },
        { $sort: { grossCents: -1 } },
      ]),
      this.paymentModel.aggregate<GroupRow>([
        { $match: range },
        { $group: { _id: '$plan', ...group } },
        { $sort: { grossCents: -1 } },
      ]),
      this.paymentModel.aggregate<GroupRow>([
        { $match: range },
        {
          $group: {
            _id: {
              $dateToString: {
                format: interval === 'month' ? '%Y-%m' : '%Y-%m-%d',
                date: '$createdAt',
              },
            },
            ...group,
          },
        },
        { $sort: { _id: 1 } },
      ]),
      this.paymentModel.aggregate<GroupRow>([
        { $match: REVENUE_MATCH },
        { $group: { _id: null, ...group } },
      ]),
    ]);

    const pricing = await this.platformSettings.resolvePricing();
    // The configured currency is the one the totals headline; anything else is
    // legacy or a misconfiguration and stays visible in the per-currency split.
    const primary =
      byCurrency.find((row) => (row._id ?? '').toUpperCase() === pricing.currency) ?? null;
    const grossCents = primary?.grossCents ?? 0;
    const payments = primary?.payments ?? 0;

    return {
      from: from.toISOString(),
      to: to.toISOString(),
      interval,
      currency: pricing.currency,
      // Headline figures are the configured currency only; `byCurrency` holds the rest.
      grossCents,
      payments,
      paymentsAllCurrencies: byCurrency.reduce((sum, row) => sum + row.payments, 0),
      averagePaymentCents: payments ? Math.round(grossCents / payments) : 0,
      allTimeGrossCents: allTime[0]?.grossCents ?? 0,
      allTimePayments: allTime[0]?.payments ?? 0,
      byCurrency: byCurrency.map(toRow),
      byProvider: byProvider.map(toRow),
      byPlan: byPlan.map(toRow),
      series: series.map((row): RevenueBucket => ({
        period: row._id ?? 'unknown',
        grossCents: row.grossCents,
        payments: row.payments,
      })),
    };
  }

  private async buildFilter(query: ListPaymentsQueryDto): Promise<FilterQuery<PaymentEventDocument>> {
    const filter: FilterQuery<PaymentEventDocument> = {};

    if (query.provider) filter.provider = query.provider;
    if (query.outcome) filter.outcome = query.outcome;
    if (query.plan) filter.plan = query.plan;
    if (query.userId) filter.userId = new Types.ObjectId(query.userId);

    if (query.from || query.to) {
      const createdAt: Record<string, Date> = {};
      if (query.from) createdAt.$gte = new Date(query.from);
      if (query.to) createdAt.$lte = new Date(query.to);
      filter.createdAt = createdAt;
    }

    if (query.q) {
      const rx = new RegExp(escapeRegExp(query.q), 'i');
      // Resolve the text to payer ids first: payment_events holds no email/name.
      const userIds = await this.userModel
        .find({ $or: [{ email: rx }, { name: rx }] })
        .select('_id')
        .limit(200)
        .lean()
        .exec();

      filter.$or = [
        { providerTxId: rx },
        { eventId: rx },
        ...(userIds.length ? [{ userId: { $in: userIds.map((u) => u._id) } }] : []),
      ];
    }

    return filter;
  }
}

function toRow(row: { _id: string | null; grossCents: number; payments: number }): {
  key: string;
  grossCents: number;
  payments: number;
} {
  return { key: row._id ?? 'unknown', grossCents: row.grossCents, payments: row.payments };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
