import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { NotificationJob, NotificationJobDocument } from './schemas/notification-job.schema';

export interface CreateNotificationJobInput {
  userId: string;
  refType: string;
  refId: string;
  category: string;
  scheduledAt: Date;
  title?: string | null;
  body?: string | null;
}

@Injectable()
export class NotificationJobsRepository {
  constructor(
    @InjectModel(NotificationJob.name)
    private readonly model: Model<NotificationJobDocument>,
  ) {}

  create(input: CreateNotificationJobInput): Promise<NotificationJobDocument> {
    return new this.model(input).save();
  }

  findByRef(refType: string, refId: string): Promise<NotificationJobDocument | null> {
    return this.model.findOne({ refType, refId, status: 'pending' }).exec();
  }

  findPendingBefore(date: Date): Promise<NotificationJobDocument[]> {
    return this.model
      .find({ status: 'pending', scheduledAt: { $lte: date } })
      .limit(100)
      .exec();
  }

  markQueued(id: string): Promise<NotificationJobDocument | null> {
    return this.model
      .findByIdAndUpdate(id, { $set: { status: 'queued' } }, { new: true })
      .exec();
  }

  markSent(id: string): Promise<NotificationJobDocument | null> {
    return this.model
      .findByIdAndUpdate(id, { $set: { status: 'sent' } }, { new: true })
      .exec();
  }

  markFailed(id: string, error: string): Promise<NotificationJobDocument | null> {
    return this.model
      .findByIdAndUpdate(
        id,
        { $set: { status: 'failed', lastError: error }, $inc: { attempts: 1 } },
        { new: true },
      )
      .exec();
  }

  cancelByRef(refType: string, refId: string): Promise<void> {
    return this.model
      .updateMany(
        { refType, refId, status: 'pending' },
        { $set: { status: 'cancelled' } },
      )
      .exec()
      .then(() => undefined);
  }

  findById(id: string): Promise<NotificationJobDocument | null> {
    return this.model.findById(id).exec();
  }

  updateById(id: string, update: UpdateQuery<NotificationJobDocument>): Promise<NotificationJobDocument | null> {
    return this.model.findByIdAndUpdate(id, update, { new: true }).exec();
  }
}
