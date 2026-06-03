import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { NotificationsModule } from '../notifications/notifications.module';

import { AiArtifactsRepository } from './ai-artifacts.repository';
import { AiJobsRepository } from './ai-jobs.repository';
import { AiRateLimiterService } from './ai-rate-limiter.service';
import { AiSettingsService } from './ai-settings.service';
import { AiWorkerService } from './ai-worker.service';
import { AiController } from './ai.controller';
import { AiJobCompletedHandler } from './handlers/ai-job-completed.handler';
import { AiArtifact, AiArtifactSchema } from './schemas/ai-artifact.schema';
import { AiJob, AiJobSchema } from './schemas/ai-job.schema';
import { AiSetting, AiSettingSchema } from './schemas/ai-setting.schema';
import { AiWorker } from './workers/ai.worker';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AiJob.name, schema: AiJobSchema },
      { name: AiArtifact.name, schema: AiArtifactSchema },
      { name: AiSetting.name, schema: AiSettingSchema },
    ]),
    CqrsModule,
    NotificationsModule,
  ],
  controllers: [AiController],
  providers: [
    AiJobsRepository,
    AiArtifactsRepository,
    AiRateLimiterService,
    AiSettingsService,
    AiWorkerService,
    AiWorker,
    AiJobCompletedHandler,
  ],
  exports: [AiJobsRepository, AiArtifactsRepository, AiSettingsService],
})
export class AiModule {}
