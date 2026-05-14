import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type ChapterDocument = HydratedDocument<Chapter>;

@Schema({ timestamps: true, collection: 'chapters' })
export class Chapter {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  subjectId!: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ required: true })
  title!: string;

  @Prop({ type: Number, default: 0 })
  order!: number;

  @Prop({ type: Boolean, default: false })
  completed!: boolean;

  @Prop({ type: Date, default: null })
  completedAt!: Date | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const ChapterSchema = SchemaFactory.createForClass(Chapter);

ChapterSchema.index({ subjectId: 1, order: 1 });
ChapterSchema.index({ title: 'text' });
