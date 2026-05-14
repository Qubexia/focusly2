import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type NotificationDocument = HydratedDocument<Notification>;

export type NotificationType = 'reminder' | 'streak' | 'reward' | 'system';

@Schema({ timestamps: true, collection: 'notifications' })
export class Notification {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['reminder', 'streak', 'reward', 'system'],
  })
  type!: NotificationType;

  @Prop({ type: String, required: true })
  title!: string;

  @Prop({ type: String, default: null })
  body!: string | null;

  @Prop({ type: SchemaTypes.Mixed, default: null })
  data!: Record<string, unknown> | null;

  @Prop({ type: Boolean, default: false })
  read!: boolean;

  @Prop({ type: Date, default: () => new Date(Date.now() + 90 * 24 * 60 * 60 * 1000) })
  expiresAt!: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);

NotificationSchema.index({ userId: 1, createdAt: -1 });
NotificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
