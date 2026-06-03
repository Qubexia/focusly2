import { Inject, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';

import { FCM_CLIENT, type FcmClient, type FcmMessage } from '../../infrastructure/fcm/fcm.tokens';
import { AuthSession, AuthSessionDocument } from '../auth/schemas/auth-session.schema';
import { Notification, NotificationDocument } from '../notifications/schemas/notification.schema';
import { User, UserDocument } from '../users/schemas/user.schema';

import { BroadcastNotificationDto } from './dto/admin-notifications.dto';

@Injectable()
export class AdminNotificationsService {
  constructor(
    @InjectModel(Notification.name) private readonly notificationModel: Model<NotificationDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(AuthSession.name) private readonly authSessionModel: Model<AuthSessionDocument>,
    @Inject(FCM_CLIENT) private readonly fcmClient: FcmClient,
  ) {}

  async broadcast(dto: BroadcastNotificationDto): Promise<unknown> {
    const userIds = await this.resolveRecipients(dto);
    if (userIds.length === 0) {
      return { recipients: 0, pushed: 0 };
    }

    const type = dto.type ?? 'system';
    const docs = userIds.map((userId) => ({
      userId,
      type,
      title: dto.title,
      body: dto.body ?? null,
      read: false,
    }));
    await this.notificationModel.insertMany(docs, { ordered: false });

    let pushed = 0;
    if (dto.push) {
      pushed = await this.pushToDevices(userIds, dto);
    }

    return { recipients: userIds.length, pushed };
  }

  async listRecent(limit = 50): Promise<unknown> {
    return this.notificationModel
      .aggregate([
        {
          $group: {
            _id: { title: '$title', type: '$type', body: '$body' },
            recipients: { $sum: 1 },
            sentAt: { $max: '$createdAt' },
          },
        },
        { $sort: { sentAt: -1 } },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            title: '$_id.title',
            type: '$_id.type',
            body: '$_id.body',
            recipients: 1,
            sentAt: 1,
          },
        },
      ])
      .exec();
  }

  private async resolveRecipients(dto: BroadcastNotificationDto): Promise<string[]> {
    if (dto.target === 'users') {
      return dto.userIds ?? [];
    }

    const filter: FilterQuery<UserDocument> = { isDeleted: false, isBanned: false };
    if (dto.target === 'premium') filter.plan = 'premium';
    if (dto.target === 'free') filter.plan = 'free';

    const rows = await this.userModel.find(filter).select('_id').lean().exec();
    return rows.map((r) => String(r._id));
  }

  private async pushToDevices(userIds: string[], dto: BroadcastNotificationDto): Promise<number> {
    const sessions = await this.authSessionModel
      .find({
        userId: { $in: userIds },
        revokedAt: null,
        expiresAt: { $gt: new Date() },
        fcmToken: { $ne: null },
      })
      .select('fcmToken')
      .lean()
      .exec();

    const messages: FcmMessage[] = sessions
      .filter((s): s is typeof s & { fcmToken: string } => Boolean(s.fcmToken))
      .map((s) => ({
        token: s.fcmToken,
        title: dto.title,
        body: dto.body ?? '',
        data: { type: dto.type ?? 'system' },
      }));

    if (messages.length === 0) return 0;
    const result = await this.fcmClient.send(messages);
    return result.successCount;
  }
}
