import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { Streak, StreakDocument, StreakReward } from './schemas/streak.schema';

@Injectable()
export class StreaksRepository {
  constructor(
    @InjectModel(Streak.name)
    private readonly model: Model<StreakDocument>,
  ) {}

  findByUserId(userId: string): Promise<StreakDocument | null> {
    return this.model.findOne({ userId }).exec();
  }

  create(userId: string): Promise<StreakDocument> {
    return new this.model({ userId }).save();
  }

  async findOrCreate(userId: string): Promise<StreakDocument> {
    const existing = await this.findByUserId(userId);
    if (existing) return existing;
    return this.create(userId);
  }

  updateStreak(
    userId: string,
    update: {
      current: number;
      longest: number;
      lastActiveDate: string;
      points: number;
      rewards: StreakReward[];
    },
  ): Promise<StreakDocument | null> {
    return this.model.findOneAndUpdate({ userId }, { $set: update }, { new: true }).exec();
  }

  resetStreak(userId: string): Promise<StreakDocument | null> {
    return this.model.findOneAndUpdate({ userId }, { $set: { current: 0 } }, { new: true }).exec();
  }

  findAllWithLastActive(): Promise<StreakDocument[]> {
    return this.model.find({ lastActiveDate: { $ne: null } }).exec();
  }
}
