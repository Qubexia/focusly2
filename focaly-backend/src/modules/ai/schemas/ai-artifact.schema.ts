import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type AiArtifactDocument = HydratedDocument<AiArtifact>;

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'ai_artifacts' })
export class AiArtifact {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  subjectId!: string;

  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  chapterId!: string | null;

  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  jobId!: string;

  @Prop({
    type: String,
    required: true,
    enum: ['summary', 'flashcards', 'questions'],
  })
  kind!: string;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  content!: Record<string, unknown>;

  createdAt!: Date;
}

export const AiArtifactSchema = SchemaFactory.createForClass(AiArtifact);
