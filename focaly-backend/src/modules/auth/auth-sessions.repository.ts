import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { AuthSession, AuthSessionDocument } from './schemas/auth-session.schema';

export interface UpsertAuthSessionInput {
  userId: string;
  deviceId: string;
  refreshTokenHash: string;
  family: string;
  expiresAt: Date;
  userAgent?: string | null;
  ip?: string | null;
  fcmToken?: string | null;
}

@Injectable()
export class AuthSessionsRepository {
  constructor(
    @InjectModel(AuthSession.name) private readonly authSessionModel: Model<AuthSessionDocument>,
  ) {}

  upsertByUserDevice(input: UpsertAuthSessionInput): Promise<AuthSessionDocument> {
    return this.authSessionModel
      .findOneAndUpdate(
        { userId: input.userId, deviceId: input.deviceId },
        {
          $set: {
            refreshTokenHash: input.refreshTokenHash,
            family: input.family,
            expiresAt: input.expiresAt,
            userAgent: input.userAgent ?? null,
            ip: input.ip ?? null,
            fcmToken: input.fcmToken ?? null,
            revokedAt: null,
          },
        },
        { new: true, upsert: true, setDefaultsOnInsert: true, runValidators: true },
      )
      .exec();
  }

  findActiveById(id: string): Promise<AuthSessionDocument | null> {
    return this.authSessionModel
      .findOne({ _id: id, revokedAt: null, expiresAt: { $gt: new Date() } })
      .exec();
  }

  findActiveByUserId(userId: string): Promise<AuthSessionDocument[]> {
    return this.authSessionModel
      .find({ userId, revokedAt: null, expiresAt: { $gt: new Date() } })
      .sort({ createdAt: -1 })
      .exec();
  }

  revokeById(userId: string, id: string): Promise<AuthSessionDocument | null> {
    return this.authSessionModel
      .findOneAndUpdate(
        { _id: id, userId, revokedAt: null },
        { $set: { revokedAt: new Date(), fcmToken: null } },
        { new: true },
      )
      .exec();
  }

  async revokeAllByUserId(userId: string): Promise<void> {
    await this.authSessionModel
      .updateMany({ userId, revokedAt: null }, { $set: { revokedAt: new Date(), fcmToken: null } })
      .exec();
  }

  async revokeFamily(userId: string, family: string): Promise<void> {
    await this.authSessionModel
      .updateMany(
        { userId, family, revokedAt: null },
        { $set: { revokedAt: new Date(), fcmToken: null } },
      )
      .exec();
  }

  updateRefreshToken(sessionId: string, refreshTokenHash: string, expiresAt: Date): Promise<void> {
    return this.authSessionModel
      .updateOne({ _id: sessionId }, { $set: { refreshTokenHash, expiresAt, revokedAt: null } })
      .exec()
      .then(() => undefined);
  }

  setFcmToken(sessionId: string, fcmToken: string | null): Promise<void> {
    return this.authSessionModel
      .updateOne({ _id: sessionId }, { $set: { fcmToken } })
      .exec()
      .then(() => undefined);
  }
}
