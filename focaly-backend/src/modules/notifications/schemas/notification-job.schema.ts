import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type NotificationJobDocument = HydratedDocument<NotificationJob>;

export type NotificationJobStatus = 'pending' | 'queued' | 'sent' | 'failed' | 'cancelled';

export type NotificationCategory = 'reminder' | 'streak' | 'reward' | 'system';

@Schema({ timestamps: true, collection: 'notification_jobs' })
export class NotificationJob {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['study_schedule', 'planned_item', 'system'],
  })
  refType!: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true })
  refId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['reminder', 'streak', 'reward', 'system'],
  })
  category!: NotificationCategory;

  @Prop({ type: Date, required: true, index: true })
  scheduledAt!: Date;

  @Prop({
    type: String,
    required: true,
    enum: ['pending', 'queued', 'sent', 'failed', 'cancelled'],
    default: 'pending',
    index: true,
  })
  status!: NotificationJobStatus;

  @Prop({ type: Number, default: 0 })
  attempts!: number;

  @Prop({ type: String, default: null })
  lastError!: string | null;

  @Prop({ type: String, default: null })
  title!: string | null;

  @Prop({ type: String, default: null })
  body!: string | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const NotificationJobSchema = SchemaFactory.createForClass(NotificationJob);

NotificationJobSchema.index({ scheduledAt: 1, status: 1 });
NotificationJobSchema.index({ refType: 1, refId: 1 });
