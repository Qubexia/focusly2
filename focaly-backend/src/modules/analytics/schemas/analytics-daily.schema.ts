import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type AnalyticsDailyDocument = HydratedDocument<AnalyticsDaily>;

@Schema({ timestamps: true, collection: 'analytics_daily' })
export class AnalyticsDaily {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: Date, required: true })
  date!: Date;

  @Prop({ type: Number, default: 0 })
  focusMinutes!: number;

  @Prop({ type: Number, default: 0 })
  completedCycles!: number;

  @Prop({ type: Number, default: 0 })
  plannedItemsCompleted!: number;

  @Prop({ type: Number, default: 0 })
  sessionsCount!: number;

  createdAt!: Date;
  updatedAt!: Date;
}

export const AnalyticsDailySchema = SchemaFactory.createForClass(AnalyticsDaily);

AnalyticsDailySchema.index({ userId: 1, date: -1 });
