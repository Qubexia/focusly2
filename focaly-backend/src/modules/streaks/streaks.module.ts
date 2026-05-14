import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { UsersModule } from '../users/users.module';

import { AdvanceStreakHandler } from './handlers/advance-streak.handler';
import { Streak, StreakSchema } from './schemas/streak.schema';
import { StreaksController } from './streaks.controller';
import { StreaksMaintenanceService } from './streaks-maintenance.service';
import { StreaksRepository } from './streaks.repository';
import { StreaksService } from './streaks.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Streak.name, schema: StreakSchema }]),
    CqrsModule,
    UsersModule,
  ],
  controllers: [StreaksController],
  providers: [StreaksService, StreaksRepository, AdvanceStreakHandler, StreaksMaintenanceService],
  exports: [StreaksRepository, StreaksService],
})
export class StreaksModule {}
