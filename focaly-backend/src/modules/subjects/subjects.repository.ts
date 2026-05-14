import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { Subject, SubjectDocument } from './schemas/subject.schema';

export interface CreateSubjectInput {
  userId: string;
  name: string;
  color?: string | null;
  icon?: string | null;
  dailyTargetMinutes?: number;
}

@Injectable()
export class SubjectsRepository {
  constructor(@InjectModel(Subject.name) private readonly subjectModel: Model<SubjectDocument>) {}

  create(input: CreateSubjectInput): Promise<SubjectDocument> {
    return new this.subjectModel(input).save();
  }

  countActiveByUser(userId: string): Promise<number> {
    return this.subjectModel.countDocuments({ userId, isArchived: false }).exec();
  }

  findActiveById(userId: string, id: string): Promise<SubjectDocument | null> {
    return this.subjectModel.findOne({ _id: id, userId, isDeleted: { $ne: true } }).exec();
  }

  findById(id: string): Promise<SubjectDocument | null> {
    return this.subjectModel.findById(id).exec();
  }

  findAllByUser(userId: string, includeArchived = false): Promise<SubjectDocument[]> {
    const filter: FilterQuery<SubjectDocument> = { userId };
    if (!includeArchived) {
      filter.isArchived = false;
    }
    return this.subjectModel.find(filter).sort({ createdAt: -1 }).exec();
  }

  updateById(id: string, update: UpdateQuery<SubjectDocument>): Promise<SubjectDocument | null> {
    return this.subjectModel
      .findByIdAndUpdate(id, update, { new: true, runValidators: true })
      .exec();
  }

  async softDelete(id: string): Promise<void> {
    await this.subjectModel.updateOne({ _id: id }, { $set: { isArchived: true } }).exec();
  }
}
