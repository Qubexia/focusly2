import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';

import { AuditLog, AuditLogDocument } from '../auth/schemas/audit-log.schema';

import { ListAuditLogsQueryDto } from './dto/admin-audit.dto';
import { paginated, Paginated, resolvePaging } from './dto/pagination.dto';

@Injectable()
export class AdminAuditService {
  constructor(
    @InjectModel(AuditLog.name) private readonly auditLogModel: Model<AuditLogDocument>,
  ) {}

  async list(query: ListAuditLogsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<AuditLogDocument> = {};

    if (query.actor) filter.actor = query.actor;
    if (query.userId) filter.userId = new Types.ObjectId(query.userId);
    if (query.actorUserId) filter.actorUserId = new Types.ObjectId(query.actorUserId);
    if (query.eventType) {
      // Prefix match so `admin.users` returns ban/unban/update/delete together.
      filter.eventType = { $regex: `^${escapeRegExp(query.eventType)}` };
    }
    if (query.from || query.to) {
      const createdAt: Record<string, Date> = {};
      if (query.from) createdAt.$gte = new Date(query.from);
      if (query.to) createdAt.$lte = new Date(query.to);
      filter.createdAt = createdAt;
    }

    const [items, total] = await Promise.all([
      this.auditLogModel.aggregate([
        { $match: filter },
        { $sort: { createdAt: -1 } },
        { $skip: skip },
        { $limit: limit },
        { $lookup: { from: 'users', localField: 'userId', foreignField: '_id', as: 'subject' } },
        {
          $lookup: {
            from: 'users',
            localField: 'actorUserId',
            foreignField: '_id',
            as: 'actorUser',
          },
        },
        { $unwind: { path: '$subject', preserveNullAndEmptyArrays: true } },
        { $unwind: { path: '$actorUser', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            actor: 1,
            eventType: 1,
            userId: 1,
            actorUserId: 1,
            ip: 1,
            userAgent: 1,
            requestId: 1,
            data: 1,
            createdAt: 1,
            'subject.email': 1,
            'subject.name': 1,
            'actorUser.email': 1,
            'actorUser.name': 1,
          },
        },
      ]),
      this.auditLogModel.countDocuments(filter).exec(),
    ]);

    return paginated(items, total, page, limit);
  }

  /** Distinct event types present, so the UI filter is never a guess. */
  async eventTypes(): Promise<string[]> {
    const types = await this.auditLogModel.distinct('eventType').exec();
    return (types as string[]).sort();
  }
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
