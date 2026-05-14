import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import {
  PomodoroSession,
  PomodoroSessionDocument,
  PomodoroStatus,
} from './schemas/pomodoro-session.schema';

export interface CreatePomodoroInput {
  userId: string;
  subjectId?: string | null;
  focusMinutes: number;
  breakMinutes: number;
  status: PomodoroStatus;
  startedAt: Date;
  lastTickAt: Date;
}

@Injectable()
export class PomodoroRepository {
  constructor(
    @InjectModel(PomodoroSession.name)
    private readonly model: Model<PomodoroSessionDocument>,
  ) {}

  create(input: CreatePomodoroInput): Promise<PomodoroSessionDocument> {
    return new this.model(input).save();
  }

  findActiveByUser(userId: string): Promise<PomodoroSessionDocument | null> {
    return this.model.findOne({ userId, status: 'active' }).sort({ startedAt: -1 }).exec();
  }

  findById(id: string): Promise<PomodoroSessionDocument | null> {
    return this.model.findById(id).exec();
  }

  updateStatus(
    id: string,
    status: PomodoroStatus,
    extra?: Partial<{
      endedAt: Date;
      totalFocusMinutes: number;
      completedCycles: number;
      lastTickAt: Date;
    }>,
  ): Promise<PomodoroSessionDocument | null> {
    return this.model
      .findByIdAndUpdate(id, { $set: { status, lastTickAt: new Date(), ...extra } }, { new: true })
      .exec();
  }

  findTodayByUser(
    userId: string,
    todayStart: Date,
    todayEnd: Date,
  ): Promise<PomodoroSessionDocument[]> {
    return this.model
      .find({
        userId,
        startedAt: { $gte: todayStart, $lte: todayEnd },
      })
      .sort({ startedAt: -1 })
      .exec();
  }

  findHistory(
    userId: string,
    from: Date,
    to: Date,
    limit: number,
    cursor?: string,
  ): Promise<PomodoroSessionDocument[]> {
    const filter: Record<string, unknown> = {
      userId,
      startedAt: { $gte: from, $lte: to },
    };
    if (cursor) {
      filter._id = { $lt: cursor };
    }
    return this.model.find(filter).sort({ startedAt: -1 }).limit(limit).exec();
  }
}
