import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type SubjectDocument = HydratedDocument<Subject>;

@Schema({ timestamps: true, collection: 'subjects' })
export class Subject {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ type: String, default: null })
  color!: string | null;

  @Prop({ type: String, default: null })
  icon!: string | null;

  @Prop({ type: Number, default: 0 })
  dailyTargetMinutes!: number;

  @Prop({ type: Number, default: 0, min: 0, max: 100 })
  progressPercent!: number;

  @Prop({ type: Boolean, default: false, index: true })
  isArchived!: boolean;

  createdAt!: Date;
  updatedAt!: Date;
}

export const SubjectSchema = SchemaFactory.createForClass(Subject);

SubjectSchema.index({ userId: 1, isArchived: 1 });
SubjectSchema.index({ name: 'text' });
