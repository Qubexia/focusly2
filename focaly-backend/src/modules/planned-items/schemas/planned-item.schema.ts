import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type PlannedItemDocument = HydratedDocument<PlannedItem>;

export type PlannedItemKind = 'task' | 'revision' | 'lecture' | 'exam';

@Schema({ timestamps: true, collection: 'planned_items', discriminatorKey: 'kind' })
export class PlannedItem {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  subjectId!: string | null;

  @Prop({
    type: String,
    required: true,
    enum: ['task', 'revision', 'lecture', 'exam'],
  })
  kind!: PlannedItemKind;

  @Prop({ type: String, required: true, trim: true })
  title!: string;

  @Prop({ type: String, default: null })
  notes!: string | null;

  @Prop({ type: Date, required: true, index: true })
  plannedAt!: Date;

  @Prop({ type: Number, default: null })
  durationMinutes!: number | null;

  @Prop({ type: String, enum: ['daily', 'weekly', 'once'], default: 'once' })
  recurrence!: 'daily' | 'weekly' | 'once';

  @Prop({ type: Number, default: 15 })
  reminderMinutesBefore!: number;

  @Prop({ type: Boolean, default: true })
  reminderEnabled!: boolean;

  @Prop({ type: Boolean, default: false })
  completed!: boolean;

  @Prop({ type: Date, default: null })
  completedAt!: Date | null;

  @Prop({ type: Number, default: 0 })
  rewardPoints!: number;

  createdAt!: Date;
  updatedAt!: Date;
}

export const PlannedItemSchema = SchemaFactory.createForClass(PlannedItem);

PlannedItemSchema.index({ userId: 1, plannedAt: 1 });
PlannedItemSchema.index({ userId: 1, kind: 1, plannedAt: 1 });
PlannedItemSchema.index({ userId: 1, completed: 1 });
