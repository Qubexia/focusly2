import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type StudyScheduleDocument = HydratedDocument<StudySchedule>;

@Schema({ timestamps: true, collection: 'study_schedules' })
export class StudySchedule {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  subjectId!: string;

  @Prop({ required: true, trim: true })
  title!: string;

  @Prop({ type: Date, required: true, index: true })
  startAt!: Date;

  @Prop({ type: Date, default: null })
  endAt!: Date | null;

  @Prop({ type: [Number], default: [] })
  daysOfWeek!: number[];

  @Prop({ type: String, default: null })
  rrule!: string | null;

  @Prop({ type: Number, default: 15 })
  reminderMinutesBefore!: number;

  @Prop({ type: Boolean, default: true })
  reminderEnabled!: boolean;

  @Prop({ type: Boolean, default: true })
  isActive!: boolean;

  createdAt!: Date;
  updatedAt!: Date;
}

export const StudyScheduleSchema = SchemaFactory.createForClass(StudySchedule);

StudyScheduleSchema.index({ userId: 1, startAt: 1 });
