import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type PaymentEventDocument = HydratedDocument<PaymentEvent>;

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'payment_events' })
export class PaymentEvent {
  @Prop({
    type: String,
    required: true,
    // `stripe` is legacy-only: the integration was removed, kept for historical rows.
    enum: ['paymob', 'google_play', 'app_store', 'stripe'],
  })
  provider!: string;

  @Prop({ type: String, required: true })
  eventId!: string;

  @Prop({ type: SchemaTypes.ObjectId, default: null })
  userId!: string | null;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  payload!: Record<string, unknown>;

  @Prop({ type: Date, default: null })
  processedAt!: Date | null;

  @Prop({
    type: String,
    enum: ['applied', 'noop', 'error'],
    default: null,
  })
  outcome!: string | null;

  @Prop({ type: String, default: null })
  error!: string | null;

  /**
   * Money actually moved, in the smallest currency unit, denormalised out of
   * `payload` so revenue can be aggregated without parsing provider-specific
   * blobs. Null when the event carries no amount (store IAP verifications,
   * status-only changes).
   */
  @Prop({ type: Number, default: null })
  amountCents!: number | null;

  @Prop({ type: String, default: null, uppercase: true, trim: true })
  currency!: string | null;

  /** Billing period this payment bought. Null when the provider did not say. */
  @Prop({ type: String, default: null })
  plan!: string | null;

  /** Provider-side transaction id, for reconciliation against their dashboard. */
  @Prop({ type: String, default: null })
  providerTxId!: string | null;

  createdAt!: Date;
}

export const PaymentEventSchema = SchemaFactory.createForClass(PaymentEvent);

PaymentEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });
PaymentEventSchema.index({ createdAt: -1 });
PaymentEventSchema.index({ outcome: 1, createdAt: -1 });
PaymentEventSchema.index({ userId: 1, createdAt: -1 });
