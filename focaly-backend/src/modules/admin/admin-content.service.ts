import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';

import { AiJob, AiJobDocument } from '../ai/schemas/ai-job.schema';
import { PlannedItem, PlannedItemDocument } from '../planned-items/schemas/planned-item.schema';
import { Subject, SubjectDocument } from '../subjects/schemas/subject.schema';

import {
  ListAiJobsQueryDto,
  ListPlannedItemsQueryDto,
  ListSubjectsQueryDto,
} from './dto/admin-content.dto';
import { paginated, Paginated, resolvePaging } from './dto/pagination.dto';

@Injectable()
export class AdminContentService {
  constructor(
    @InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>,
    @InjectModel(PlannedItem.name) private readonly plannedItemModel: Model<PlannedItemDocument>,
    @InjectModel(AiJob.name) private readonly aiJobModel: Model<AiJobDocument>,
  ) {}

  async listSubjects(query: ListSubjectsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<SubjectDocument> = {};
    if (query.userId) filter.userId = query.userId;

    const [items, total] = await Promise.all([
      this.subjectModel.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean().exec(),
      this.subjectModel.countDocuments(filter).exec(),
    ]);
    return paginated(items, total, page, limit);
  }

  async listPlannedItems(query: ListPlannedItemsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<PlannedItemDocument> = {};
    if (query.userId) filter.userId = query.userId;
    if (query.kind) filter.kind = query.kind;

    const [items, total] = await Promise.all([
      this.plannedItemModel
        .find(filter)
        .sort({ plannedAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.plannedItemModel.countDocuments(filter).exec(),
    ]);
    return paginated(items, total, page, limit);
  }

  async listAiJobs(query: ListAiJobsQueryDto): Promise<Paginated<unknown>> {
    const { page, limit, skip } = resolvePaging(query.page, query.limit);
    const filter: FilterQuery<AiJobDocument> = {};
    if (query.userId) filter.userId = query.userId;
    if (query.status) filter.status = query.status;

    const [items, total] = await Promise.all([
      this.aiJobModel.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean().exec(),
      this.aiJobModel.countDocuments(filter).exec(),
    ]);
    return paginated(items, total, page, limit);
  }
}
