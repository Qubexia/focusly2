import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { PaymentEvent, PaymentEventDocument } from './schemas/payment-event.schema';

export interface CreatePaymentEventInput {
  provider: string;
  eventId: string;
  userId?: string | null;
  payload: Record<string, unknown>;
}

@Injectable()
export class PaymentEventsRepository {
  constructor(
    @InjectModel(PaymentEvent.name)
    private readonly model: Model<PaymentEventDocument>,
  ) {}

  async insertIdempotent(
    input: CreatePaymentEventInput,
  ): Promise<{ event: PaymentEventDocument; isNew: boolean }> {
    const existing = await this.model.findOne({
      provider: input.provider,
      eventId: input.eventId,
    }).exec();

    if (existing) {
      return { event: existing, isNew: false };
    }

    const event = await new this.model(input).save();
    return { event, isNew: true };
  }

  markProcessed(id: string, outcome: string, error?: string): Promise<PaymentEventDocument | null> {
    return this.model
      .findByIdAndUpdate(
        id,
        { $set: { processedAt: new Date(), outcome, error: error ?? null } },
        { new: true },
      )
      .exec();
  }
}
