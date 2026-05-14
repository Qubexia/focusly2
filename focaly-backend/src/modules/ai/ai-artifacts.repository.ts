import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { AiArtifact, AiArtifactDocument } from './schemas/ai-artifact.schema';

export interface CreateAiArtifactInput {
  userId: string;
  subjectId: string;
  jobId: string;
  kind: string;
  content: Record<string, unknown>;
}

@Injectable()
export class AiArtifactsRepository {
  constructor(
    @InjectModel(AiArtifact.name)
    private readonly model: Model<AiArtifactDocument>,
  ) {}

  create(input: CreateAiArtifactInput): Promise<AiArtifactDocument> {
    return new this.model(input).save();
  }

  findBySubject(userId: string, subjectId: string): Promise<AiArtifactDocument[]> {
    return this.model.find({ userId, subjectId }).sort({ createdAt: -1 }).exec();
  }

  findByJob(jobId: string): Promise<AiArtifactDocument[]> {
    return this.model.find({ jobId }).exec();
  }
}
