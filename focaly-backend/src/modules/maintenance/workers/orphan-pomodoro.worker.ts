import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Cron } from '@nestjs/schedule';
import { Model } from 'mongoose';

import { computeFocusStats } from '../../pomodoro/pomodoro.util';
import {
  PomodoroSession,
  PomodoroSessionDocument,
} from '../../pomodoro/schemas/pomodoro-session.schema';

@Injectable()
export class OrphanPomodoroWorker {
  private readonly logger = new Logger(OrphanPomodoroWorker.name);

  constructor(
    @InjectModel(PomodoroSession.name)
    private readonly pomodoroModel: Model<PomodoroSessionDocument>,
  ) {}

  @Cron('0 */15 * * * *')
  async abortOrphanSessions(): Promise<void> {
    const cutoff = new Date(Date.now() - 4 * 3600_000);
    const orphans = await this.pomodoroModel
      .find({ status: 'active', lastTickAt: { $lt: cutoff } })
      .exec();

    const maxElapsedMs = 4 * 3600_000;
    for (const session of orphans) {
      const elapsedMs = Date.now() - session.startedAt.getTime();
      const { totalFocusMinutes, completedCycles } = computeFocusStats({
        focusMinutes: session.focusMinutes,
        breakMinutes: session.breakMinutes,
        sessionMinutes: session.sessionMinutes,
        elapsedMs: Math.min(elapsedMs, maxElapsedMs),
      });

      await this.pomodoroModel
        .updateOne(
          { _id: session.id },
          {
            $set: {
              status: 'aborted',
              endedAt: new Date(session.startedAt.getTime() + maxElapsedMs),
              totalFocusMinutes,
              completedCycles,
            },
          },
        )
        .exec();
    }

    if (orphans.length > 0) {
      this.logger.log(`Auto-aborted ${orphans.length} orphaned pomodoro sessions`);
    }
  }
}
