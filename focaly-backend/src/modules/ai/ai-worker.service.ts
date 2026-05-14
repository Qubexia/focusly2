import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';

import { QUEUE_AI } from '../../infrastructure/queue/queue.constants';

@Injectable()
export class AiWorkerService {
  constructor(
    @InjectQueue(QUEUE_AI)
    private readonly queue: Queue,
  ) {}

  async enqueueJob(jobId: string, userId: string, subjectId: string | null): Promise<void> {
    await this.queue.add('process', { jobId, userId, subjectId });
  }
}
