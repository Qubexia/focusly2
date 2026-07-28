import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { UsersModule } from '../users/users.module';

import { PomodoroController } from './pomodoro.controller';
import { PomodoroRepository } from './pomodoro.repository';
import { PomodoroService } from './pomodoro.service';
import { PomodoroSession, PomodoroSessionSchema } from './schemas/pomodoro-session.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: PomodoroSession.name, schema: PomodoroSessionSchema }]),
    UsersModule,
  ],
  controllers: [PomodoroController],
  providers: [PomodoroService, PomodoroRepository],
  exports: [PomodoroService, PomodoroRepository],
})
export class PomodoroModule {}
