import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { Notification, NotificationDocument } from './schemas/notification.schema';

export interface CreateNotificationInput {
  userId: string;
  type: string;
  title: string;
  body?: string | null;
  data?: Record<string, unknown> | null;
}

@Injectable()
export class NotificationsRepository {
  constructor(
    @InjectModel(Notification.name)
    private readonly model: Model<NotificationDocument>,
  ) {}

  create(input: CreateNotificationInput): Promise<NotificationDocument> {
    return new this.model(input).save();
  }

  findAllByUser(
    userId: string,
    limit = 50,
    cursor?: string,
  ): Promise<NotificationDocument[]> {
    const filter: FilterQuery<NotificationDocument> = { userId };
    if (cursor) {
      filter._id = { $lt: cursor };
    }
    return this.model.find(filter).sort({ createdAt: -1 }).limit(limit).exec();
  }

  findById(id: string): Promise<NotificationDocument | null> {
    return this.model.findById(id).exec();
  }

  markRead(id: string): Promise<NotificationDocument | null> {
    return this.model.findByIdAndUpdate(id, { $set: { read: true } }, { new: true }).exec();
  }

  markAllRead(userId: string): Promise<void> {
    return this.model
      .updateMany({ userId, read: false }, { $set: { read: true } })
      .exec()
      .then(() => undefined);
  }

  async hardDelete(id: string): Promise<void> {
    await this.model.deleteOne({ _id: id }).exec();
  }

  async deleteAllByUser(userId: string): Promise<void> {
    await this.model.deleteMany({ userId }).exec();
  }

  updateById(id: string, update: UpdateQuery<NotificationDocument>): Promise<NotificationDocument | null> {
    return this.model.findByIdAndUpdate(id, update, { new: true }).exec();
  }
}
