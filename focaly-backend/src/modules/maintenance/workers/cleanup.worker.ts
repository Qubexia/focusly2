import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Cron } from '@nestjs/schedule';
import { Model } from 'mongoose';

import { User, UserDocument } from '../../users/schemas/user.schema';

@Injectable()
export class CleanupWorker {
  private readonly logger = new Logger(CleanupWorker.name);

  constructor(
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
  ) {}

  @Cron('0 4 * * *')
  async purgeSoftDeletedUsers(): Promise<void> {
    const cutoff = new Date(Date.now() - 30 * 86400_000);
    const expired = await this.userModel
      .find({ isDeleted: true, deletedAt: { $lt: cutoff } })
      .exec();

    for (const user of expired) {
      await this.userModel.deleteOne({ _id: user.id }).exec();
    }

    if (expired.length > 0) {
      this.logger.log(`Purged ${expired.length} soft-deleted users older than 30 days`);
    }
  }
}
