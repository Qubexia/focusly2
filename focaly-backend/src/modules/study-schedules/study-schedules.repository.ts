import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types, UpdateQuery } from 'mongoose';

import {
  ScheduleCompletion,
  ScheduleCompletionDocument,
} from './schemas/schedule-completion.schema';
import { StudySchedule, StudyScheduleDocument } from './schemas/study-schedule.schema';

export interface CreateStudyScheduleInput {
  userId: string;
  subjectId: string;
  title: string;
  startAt: Date;
  endAt?: Date | null;
  daysOfWeek: number[];
  rrule?: string | null;
  reminderMinutesBefore?: number;
  reminderEnabled?: boolean;
}

@Injectable()
export class StudySchedulesRepository {
  constructor(
    @InjectModel(StudySchedule.name)
    private readonly model: Model<StudyScheduleDocument>,
    @InjectModel(ScheduleCompletion.name)
    private readonly completionModel: Model<ScheduleCompletionDocument>,
  ) {}

  create(input: CreateStudyScheduleInput): Promise<StudyScheduleDocument> {
    return new this.model(input).save();
  }

  findById(id: string): Promise<StudyScheduleDocument | null> {
    return this.model.findById(id).exec();
  }

  findActiveByUserInRange(userId: string, from: Date, to: Date): Promise<StudyScheduleDocument[]> {
    return this.model
      .find({
        userId,
        isActive: true,
        startAt: { $lte: to },
        $or: [{ endAt: { $gte: from } }, { endAt: null }],
      })
      .sort({ startAt: 1 })
      .exec();
  }

  updateById(
    id: string,
    update: UpdateQuery<StudyScheduleDocument>,
  ): Promise<StudyScheduleDocument | null> {
    return this.model.findByIdAndUpdate(id, update, { new: true, runValidators: true }).exec();
  }

  async deleteById(id: string): Promise<void> {
    await this.model.deleteOne({ _id: id }).exec();
  }

  upsertCompletion(
    userId: string,
    scheduleId: string,
    date: string,
  ): Promise<ScheduleCompletionDocument | null> {
    return this.completionModel
      .findOneAndUpdate(
        { userId, scheduleId, date },
        { $setOnInsert: { userId, scheduleId, date } },
        { new: true, upsert: true },
      )
      .exec();
  }

  findCompletionsByUserInRange(
    userId: string,
    from: string,
    to: string,
  ): Promise<ScheduleCompletionDocument[]> {
    return this.completionModel.find({ userId, date: { $gte: from, $lte: to } }).exec();
  }

  async deleteCompletionsBySchedule(scheduleId: string): Promise<void> {
    await this.completionModel.deleteMany({ scheduleId: toObjectIdIfPossible(scheduleId) }).exec();
  }
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}
