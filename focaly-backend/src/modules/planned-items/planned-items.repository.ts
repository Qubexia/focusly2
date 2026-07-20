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
  daysOfWeek?: number[];
  recurrenceEndAt?: Date | null;
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
    options: {
      subjectId?: string;
      from?: string;
      to?: string;
      includeCompleted?: boolean;
    } = {},
  ): Promise<PlannedItemDocument[]> {
    const filter: FilterQuery<PlannedItemDocument> = { userId };
    if (kind) {
      filter.kind = kind;
    }
    if (!options.includeCompleted) {
      filter.completed = false;
    }
    // Scope to a single subject's planner. Items belonging to other subjects
    // (or general items with no subject) are excluded.
    if (options.subjectId) {
      filter.subjectId = options.subjectId;
    }
    // Restrict to the requested day(s). `from`/`to` arrive as date-only strings
    // (e.g. "2026-06-25"); cover the full local span by going to end-of-day on `to`.
    const plannedAt: { $gte?: Date; $lte?: Date } = {};
    if (options.from) {
      plannedAt.$gte = new Date(`${options.from}T00:00:00.000`);
    }
    if (options.to) {
      plannedAt.$lte = new Date(`${options.to}T23:59:59.999`);
    }
    if (plannedAt.$gte || plannedAt.$lte) {
      // A recurring item is a rule, not an occurrence: its `plannedAt` is only
      // the series start, so a date filter would hide it on every later day.
      // Return the rule whenever it can still yield an occurrence in the range
      // and let the client expand it against the viewer's own timezone.
      const recurring: FilterQuery<PlannedItemDocument> = {
        recurrence: { $ne: 'once' },
      };
      if (plannedAt.$lte) {
        recurring.plannedAt = { $lte: plannedAt.$lte };
      }
      if (plannedAt.$gte) {
        recurring.$or = [{ recurrenceEndAt: null }, { recurrenceEndAt: { $gte: plannedAt.$gte } }];
      }
      filter.$or = [{ recurrence: 'once', plannedAt }, recurring];
    }
    return this.model.find(filter).sort({ plannedAt: -1 }).exec();
  }

  /** Marks a single occurrence of a recurring item done, keyed by `YYYY-MM-DD`. */
  completeOccurrence(id: string, date: string): Promise<PlannedItemDocument | null> {
    return this.model
      .findByIdAndUpdate(id, { $addToSet: { completedDates: date } }, { new: true })
      .exec();
  }

  updateById(
    id: string,
    update: UpdateQuery<PlannedItemDocument>,
  ): Promise<PlannedItemDocument | null> {
    return this.model.findByIdAndUpdate(id, update, { new: true, runValidators: true }).exec();
  }

  async softDelete(id: string): Promise<void> {
    await this.model.updateOne({ _id: id }, { $set: { completed: true } }).exec();
  }

  async hardDelete(id: string): Promise<void> {
    await this.model.deleteOne({ _id: id }).exec();
  }
}
