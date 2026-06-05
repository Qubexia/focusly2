import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type AiJobDocument = HydratedDocument<AiJob>;
export type AiJobStatus = 'queued' | 'processing' | 'completed' | 'failed';

@Schema({ timestamps: true, collection: 'ai_jobs' })
export class AiJob {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  subjectId!: string | null;

  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  chapterId!: string | null;

  @Prop({ type: [String], default: [] })
  imageKeys!: string[];

  @Prop({ type: [String], default: [] })
  pdfKeys!: string[];

  @Prop({ type: String, default: null })
  language!: string | null;

  @Prop({ type: String, default: null })
  detailLevel!: string | null;

  @Prop({
    type: String,
    required: true,
    enum: ['queued', 'processing', 'completed', 'failed'],
    default: 'queued',
    index: true,
  })
  status!: AiJobStatus;

  @Prop({ type: String, default: null })
  failureReason!: string | null;

  @Prop({ type: String, default: null })
  ocrCacheHash!: string | null;

  @Prop({ type: Number, default: null })
  tokensIn!: number | null;

  @Prop({ type: Number, default: null })
  tokensOut!: number | null;

  @Prop({ type: Date, default: null })
  startedAt!: Date | null;

  @Prop({ type: Date, default: null })
  completedAt!: Date | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const AiJobSchema = SchemaFactory.createForClass(AiJob);

AiJobSchema.index({ userId: 1, status: 1 });
AiJobSchema.index({ userId: 1, createdAt: -1 });
