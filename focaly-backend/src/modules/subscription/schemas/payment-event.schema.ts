import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type PaymentEventDocument = HydratedDocument<PaymentEvent>;

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'payment_events' })
export class PaymentEvent {
  @Prop({
    type: String,
    required: true,
    enum: ['stripe', 'google_play', 'app_store', 'paymob'],
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

  createdAt!: Date;
}

export const PaymentEventSchema = SchemaFactory.createForClass(PaymentEvent);

PaymentEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });
