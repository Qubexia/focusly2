import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type ScheduleCompletionDocument = HydratedDocument<ScheduleCompletion>;

/**
 * Marks a single occurrence of a (recurring) study schedule as completed.
 * Schedules repeat weekly, so completion is tracked per local date.
 */
@Schema({ timestamps: true, collection: 'schedule_completions' })
export class ScheduleCompletion {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  scheduleId!: string;

  /** Local occurrence date, formatted 'YYYY-MM-DD'. */
  @Prop({ type: String, required: true })
  date!: string;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ScheduleCompletionSchema = SchemaFactory.createForClass(ScheduleCompletion);

ScheduleCompletionSchema.index({ userId: 1, scheduleId: 1, date: 1 }, { unique: true });
ScheduleCompletionSchema.index({ userId: 1, date: 1 });
