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

  /**
   * Weekdays a `weekly` item repeats on, Sun=0..Sat=6. Empty falls back to the
   * weekday of `plannedAt`. Ignored for `daily` and `once`.
   */
  @Prop({ type: [Number], default: [] })
  daysOfWeek!: number[];

  /** Last day the recurrence yields occurrences. Null repeats indefinitely. */
  @Prop({ type: Date, default: null })
  recurrenceEndAt!: Date | null;

  /**
   * `YYYY-MM-DD` of each occurrence the user ticked off. Recurring items are
   * completed per day, so the flat `completed` flag stays false for them and is
   * only authoritative for one-off items.
   */
  @Prop({ type: [String], default: [] })
  completedDates!: string[];

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
