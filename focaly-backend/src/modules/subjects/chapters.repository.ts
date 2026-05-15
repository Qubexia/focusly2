import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { Chapter, ChapterDocument } from './schemas/chapter.schema';

export interface CreateChapterInput {
  subjectId: string;
  userId: string;
  title: string;
  order?: number;
}

export interface ChapterStats {
  total: number;
  completed: number;
}

@Injectable()
export class ChaptersRepository {
  constructor(@InjectModel(Chapter.name) private readonly chapterModel: Model<ChapterDocument>) {}

  create(input: CreateChapterInput): Promise<ChapterDocument> {
    return new this.chapterModel(input).save();
  }

  findBySubject(subjectId: string): Promise<ChapterDocument[]> {
    return this.chapterModel.find({ subjectId }).sort({ order: 1, createdAt: 1 }).exec();
  }

  findById(subjectId: string, chapterId: string): Promise<ChapterDocument | null> {
    return this.chapterModel.findOne({ _id: chapterId, subjectId }).exec();
  }

  updateById(
    chapterId: string,
    update: Partial<Pick<Chapter, 'title' | 'order' | 'completed' | 'completedAt'>>,
  ): Promise<ChapterDocument | null> {
    return this.chapterModel
      .findByIdAndUpdate(chapterId, { $set: update }, { new: true, runValidators: true })
      .exec();
  }

  async deleteBySubject(subjectId: string): Promise<void> {
    await this.chapterModel.deleteMany({ subjectId }).exec();
  }

  async getStats(subjectId: string): Promise<ChapterStats> {
    const normalizedSubjectId = Types.ObjectId.isValid(subjectId)
      ? new Types.ObjectId(subjectId)
      : subjectId;

    const [result] = await this.chapterModel
      .aggregate<ChapterStats>([
        { $match: { subjectId: normalizedSubjectId } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            completed: { $sum: { $cond: ['$completed', 1, 0] } },
          },
        },
      ])
      .exec();

    return result ?? { total: 0, completed: 0 };
  }
}
