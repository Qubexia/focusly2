import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformSettingsModule } from '../platform-settings/platform-settings.module';
import { UsersModule } from '../users/users.module';

import { ChaptersRepository } from './chapters.repository';
import { ChaptersService } from './chapters.service';
import { RecomputeProgressHandler } from './handlers/recompute-progress.handler';
import { Chapter, ChapterSchema } from './schemas/chapter.schema';
import { Subject, SubjectSchema } from './schemas/subject.schema';
import { SubjectsController } from './subjects.controller';
import { SubjectsRepository } from './subjects.repository';
import { SubjectsService } from './subjects.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subject.name, schema: SubjectSchema },
      { name: Chapter.name, schema: ChapterSchema },
    ]),
    CqrsModule,
    PlatformSettingsModule,
    UsersModule,
  ],
  controllers: [SubjectsController],
  providers: [
    SubjectsService,
    SubjectsRepository,
    ChaptersService,
    ChaptersRepository,
    RecomputeProgressHandler,
  ],
  exports: [SubjectsService, SubjectsRepository],
})
export class SubjectsModule {}
