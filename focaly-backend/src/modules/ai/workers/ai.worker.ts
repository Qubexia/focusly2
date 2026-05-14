import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';
import { Job } from 'bullmq';

import { QUEUE_AI } from '../../../infrastructure/queue/queue.constants';
import { AiJobCompletedEvent } from '../../../shared/events/ai-job-completed.event';
import { AiArtifactsRepository } from '../ai-artifacts.repository';
import { AiJobsRepository } from '../ai-jobs.repository';

interface AiJobData {
  jobId: string;
  userId: string;
  subjectId: string | null;
}

@Processor(QUEUE_AI)
export class AiWorker extends WorkerHost {
  private readonly logger = new Logger(AiWorker.name);

  constructor(
    private readonly aiJobsRepo: AiJobsRepository,
    private readonly aiArtifactsRepo: AiArtifactsRepository,
    private readonly eventBus: EventBus,
  ) {
    super();
  }

  async process(job: Job<AiJobData>): Promise<void> {
    const { jobId, userId, subjectId } = job.data;

    await this.aiJobsRepo.updateStatus(jobId, 'processing', { startedAt: new Date() });

    try {
      if (subjectId) {
        await this.aiArtifactsRepo.create({
          userId,
          subjectId,
          jobId,
          kind: 'summary',
          content: { text: 'Fixture: lecture summary would appear here.' },
        });
      }

      await this.aiJobsRepo.updateStatus(jobId, 'completed', {
        completedAt: new Date(),
        tokensIn: 0,
        tokensOut: 0,
      });

      this.eventBus.publish(new AiJobCompletedEvent(userId, jobId, subjectId ?? '', []));
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Unknown error';
      this.logger.error(`AI job ${jobId} failed: ${msg}`);
      await this.aiJobsRepo.updateStatus(jobId, 'failed', {
        failureReason: msg,
        completedAt: new Date(),
      });
    }
  }
}
