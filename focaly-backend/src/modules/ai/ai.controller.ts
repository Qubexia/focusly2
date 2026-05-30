import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpException,
  HttpStatus,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { PremiumGuard } from '../../common/guards/premium.guard';

import { AiArtifactsRepository } from './ai-artifacts.repository';
import { AiJobsRepository } from './ai-jobs.repository';
import { AiRateLimiterService } from './ai-rate-limiter.service';
import { SubmitAiNotesJobDto } from './dto';
import { AiWorkerService } from './ai-worker.service';

@UseGuards(PremiumGuard)
@ApiTags('AI')
@Controller({ path: 'ai', version: '1' })
export class AiController {
  constructor(
    private readonly aiJobsRepo: AiJobsRepository,
    private readonly aiArtifactsRepo: AiArtifactsRepository,
    private readonly rateLimiter: AiRateLimiterService,
    private readonly aiWorkerService: AiWorkerService,
  ) {}

  @Post('notes/jobs')
  @HttpCode(HttpStatus.ACCEPTED)
  async submitJob(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: SubmitAiNotesJobDto,
  ) {
    const rateCheck = await this.rateLimiter.check(user.id);
    if (!rateCheck.allowed) {
      throw new HttpException(
        {
          error: 'AI_RATE_LIMIT',
          message: 'AI rate limit reached. Try again later.',
          retryAfterMs: rateCheck.retryAfterMs,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const job = await this.aiJobsRepo.create({
      userId: user.id,
      subjectId: dto.subjectId ?? null,
      imageKeys: dto.imageKeys,
    });

    await this.rateLimiter.increment(user.id);
    await this.aiWorkerService.enqueueJob(job.id, user.id, dto.subjectId ?? null);

    return { jobId: job.id, status: 'queued' };
  }

  @Get('notes/jobs/:id')
  async getJob(@Param('id') id: string) {
    return this.aiJobsRepo.findById(id);
  }

  @Get('artifacts')
  async getArtifacts(
    @CurrentUser() user: CurrentUserPayload,
    @Query('subjectId') subjectId: string,
  ) {
    return this.aiArtifactsRepo.findBySubject(user.id, subjectId);
  }
}
