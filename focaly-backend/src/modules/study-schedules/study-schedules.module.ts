import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { ScheduleCompletion, ScheduleCompletionSchema } from './schemas/schedule-completion.schema';
import { StudySchedule, StudyScheduleSchema } from './schemas/study-schedule.schema';
import { StudySchedulesController } from './study-schedules.controller';
import { StudySchedulesRepository } from './study-schedules.repository';
import { StudySchedulesService } from './study-schedules.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StudySchedule.name, schema: StudyScheduleSchema },
      { name: ScheduleCompletion.name, schema: ScheduleCompletionSchema },
    ]),
  ],
  controllers: [StudySchedulesController],
  providers: [StudySchedulesService, StudySchedulesRepository],
  exports: [StudySchedulesService],
})
export class StudySchedulesModule {}
