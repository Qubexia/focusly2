import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type SubscriptionDocument = HydratedDocument<Subscription>;
/**
 * `stripe` is legacy-only: the integration was removed, kept so existing rows
 * stay readable. `manual` marks premium granted by an admin, not bought.
 */
export type Provider = 'paymob' | 'google_play' | 'app_store' | 'stripe' | 'manual';
export type SubscriptionStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'expired';

@Schema({ timestamps: true, collection: 'subscriptions' })
export class Subscription {
  @Prop({ type: SchemaTypes.ObjectId, required: true, unique: true })
  userId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['paymob', 'google_play', 'app_store', 'stripe', 'manual'],
  })
  provider!: Provider;

  @Prop({ type: String, required: true })
  providerSubId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['trialing', 'active', 'past_due', 'canceled', 'expired'],
  })
  status!: SubscriptionStatus;

  @Prop({ type: Date, default: null })
  currentPeriodEnd!: Date | null;

  @Prop({ type: String, default: null })
  priceId!: string | null;

  @Prop({ type: Date, default: null })
  lastEventAt!: Date | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SubscriptionSchema = SchemaFactory.createForClass(Subscription);

SubscriptionSchema.index({ provider: 1, providerSubId: 1 }, { unique: true });
