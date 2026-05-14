import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { Subscription, SubscriptionDocument } from './schemas/subscription.schema';

export interface CreateSubscriptionInput {
  userId: string;
  provider: string;
  providerSubId: string;
  status: string;
  currentPeriodEnd?: Date | null;
  priceId?: string | null;
  lastEventAt?: Date | null;
}

@Injectable()
export class SubscriptionsRepository {
  constructor(
    @InjectModel(Subscription.name)
    private readonly model: Model<SubscriptionDocument>,
  ) {}

  findByUserId(userId: string): Promise<SubscriptionDocument | null> {
    return this.model.findOne({ userId }).exec();
  }

  findByProvider(provider: string, providerSubId: string): Promise<SubscriptionDocument | null> {
    return this.model.findOne({ provider, providerSubId }).exec();
  }

  upsert(
    userId: string,
    input: CreateSubscriptionInput,
  ): Promise<SubscriptionDocument> {
    return this.model
      .findOneAndUpdate(
        { userId },
        { $set: input },
        { upsert: true, new: true, runValidators: true },
      )
      .exec();
  }

  updateByUserId(
    userId: string,
    update: UpdateQuery<SubscriptionDocument>,
  ): Promise<SubscriptionDocument | null> {
    return this.model
      .findOneAndUpdate({ userId }, update, { new: true })
      .exec();
  }

  findAllActive(): Promise<SubscriptionDocument[]> {
    return this.model.find({ status: 'active' }).exec();
  }
}
