import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { AiArtifactsRepository } from './ai-artifacts.repository';
import { AiController } from './ai.controller';
import { AiJobsRepository } from './ai-jobs.repository';
import { AiRateLimiterService } from './ai-rate-limiter.service';
import { AiWorkerService } from './ai-worker.service';
import { AiWorker } from './workers/ai.worker';
import { AiJobCompletedHandler } from './handlers/ai-job-completed.handler';
import { AiJob, AiJobSchema } from './schemas/ai-job.schema';
import { AiArtifact, AiArtifactSchema } from './schemas/ai-artifact.schema';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AiJob.name, schema: AiJobSchema },
      { name: AiArtifact.name, schema: AiArtifactSchema },
    ]),
    CqrsModule,
    NotificationsModule,
  ],
  controllers: [AiController],
  providers: [
    AiJobsRepository,
    AiArtifactsRepository,
    AiRateLimiterService,
    AiWorkerService,
    AiWorker,
    AiJobCompletedHandler,
  ],
  exports: [AiJobsRepository, AiArtifactsRepository],
})
export class AiModule {}
