import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { AiJob, AiJobDocument, AiJobStatus } from './schemas/ai-job.schema';

export interface CreateAiJobInput {
  userId: string;
  subjectId?: string | null;
  imageKeys: string[];
}

@Injectable()
export class AiJobsRepository {
  constructor(
    @InjectModel(AiJob.name)
    private readonly model: Model<AiJobDocument>,
  ) {}

  create(input: CreateAiJobInput): Promise<AiJobDocument> {
    return new this.model(input).save();
  }

  findById(id: string): Promise<AiJobDocument | null> {
    return this.model.findById(id).exec();
  }

  findByUser(userId: string, limit = 20): Promise<AiJobDocument[]> {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).exec();
  }

  updateStatus(
    id: string,
    status: AiJobStatus,
    extra?: Partial<{
      failureReason: string;
      ocrCacheHash: string;
      tokensIn: number;
      tokensOut: number;
      startedAt: Date;
      completedAt: Date;
    }>,
  ): Promise<AiJobDocument | null> {
    const update: UpdateQuery<AiJobDocument> = { $set: { status, ...extra } };
    return this.model.findByIdAndUpdate(id, update, { new: true }).exec();
  }
}
