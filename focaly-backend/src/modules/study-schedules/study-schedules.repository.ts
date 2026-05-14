import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, UpdateQuery } from 'mongoose';

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
}
