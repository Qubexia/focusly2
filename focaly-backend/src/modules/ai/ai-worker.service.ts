import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';

import { redisDisabled } from '../../config/runtime-flags';
import { QUEUE_AI } from '../../infrastructure/queue/queue.constants';

import { AiWorker } from './workers/ai.worker';

@Injectable()
export class AiWorkerService {
  private readonly logger = new Logger(AiWorkerService.name);

  constructor(
    @InjectQueue(QUEUE_AI)
    private readonly queue: Queue,
    private readonly aiWorker: AiWorker,
  ) {}

  async enqueueJob(
    jobId: string,
    userId: string,
    subjectId: string | null,
    chapterId: string | null = null,
  ): Promise<void> {
    const data = { jobId, userId, subjectId, chapterId };

    if (redisDisabled) {
      // No queue in local dev — process inline (fire-and-forget). The client
      // polls the job status, so we don't block the HTTP response on it.
      void this.aiWorker.runJob(data).catch((err: unknown) => {
        const msg = err instanceof Error ? err.message : 'Unknown error';
        this.logger.error(`Inline AI job ${jobId} failed: ${msg}`);
      });
      return;
    }

    await this.queue.add('process', data);
  }
}
