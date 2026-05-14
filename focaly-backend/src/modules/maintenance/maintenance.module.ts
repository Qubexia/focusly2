import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { PomodoroSession, PomodoroSessionSchema } from '../pomodoro/schemas/pomodoro-session.schema';
import { User, UserSchema } from '../users/schemas/user.schema';

import { CleanupWorker } from './workers/cleanup.worker';
import { OrphanPomodoroWorker } from './workers/orphan-pomodoro.worker';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PomodoroSession.name, schema: PomodoroSessionSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  providers: [OrphanPomodoroWorker, CleanupWorker],
})
export class MaintenanceModule {}
