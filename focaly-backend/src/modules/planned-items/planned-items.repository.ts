import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { PlannedItem, PlannedItemDocument, PlannedItemKind } from './schemas/planned-item.schema';

export interface CreatePlannedItemInput {
  userId: string;
  subjectId?: string | null;
  kind: PlannedItemKind;
  title: string;
  notes?: string | null;
  plannedAt: Date;
  durationMinutes?: number | null;
  recurrence?: 'daily' | 'weekly' | 'once';
  reminderMinutesBefore?: number;
  reminderEnabled?: boolean;
  rewardPoints?: number;
}

@Injectable()
export class PlannedItemsRepository {
  constructor(
    @InjectModel(PlannedItem.name)
    private readonly model: Model<PlannedItemDocument>,
  ) {}

  create(input: CreatePlannedItemInput): Promise<PlannedItemDocument> {
    return new this.model(input).save();
  }

  findById(id: string): Promise<PlannedItemDocument | null> {
    return this.model.findById(id).exec();
  }

  findAllByUser(
    userId: string,
    kind?: PlannedItemKind,
    includeCompleted = false,
  ): Promise<PlannedItemDocument[]> {
    const filter: FilterQuery<PlannedItemDocument> = { userId };
    if (kind) {
      filter.kind = kind;
    }
    if (!includeCompleted) {
      filter.completed = false;
    }
    return this.model.find(filter).sort({ plannedAt: -1 }).exec();
  }

  updateById(id: string, update: UpdateQuery<PlannedItemDocument>): Promise<PlannedItemDocument | null> {
    return this.model.findByIdAndUpdate(id, update, { new: true, runValidators: true }).exec();
  }

  async softDelete(id: string): Promise<void> {
    await this.model.updateOne({ _id: id }, { $set: { completed: true } }).exec();
  }

  async hardDelete(id: string): Promise<void> {
    await this.model.deleteOne({ _id: id }).exec();
  }
}
