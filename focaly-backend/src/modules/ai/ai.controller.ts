import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpException,
  HttpStatus,
  NotFoundException,
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
import { AiSettingsService } from './ai-settings.service';
import { AiWorkerService } from './ai-worker.service';
import { SubmitAiNotesJobDto } from './dto';

@UseGuards(PremiumGuard)
@ApiTags('AI')
@Controller({ path: 'ai', version: '1' })
export class AiController {
  constructor(
    private readonly aiJobsRepo: AiJobsRepository,
    private readonly aiArtifactsRepo: AiArtifactsRepository,
    private readonly rateLimiter: AiRateLimiterService,
    private readonly aiWorkerService: AiWorkerService,
    private readonly aiSettings: AiSettingsService,
  ) {}

  @Post('notes/jobs')
  @HttpCode(HttpStatus.ACCEPTED)
  async submitJob(@CurrentUser() user: CurrentUserPayload, @Body() dto: SubmitAiNotesJobDto) {
    const settings = await this.aiSettings.resolve();
    if (!settings.enabled || !settings.apiKey) {
      throw new HttpException(
        {
          error: 'AI_UNAVAILABLE',
          message: 'AI features are currently unavailable. Please try again later.',
        },
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

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
      chapterId: dto.chapterId ?? null,
      imageKeys: dto.imageKeys ?? [],
      pdfKeys: dto.pdfKeys ?? [],
      language: dto.language ?? null,
      detailLevel: dto.detailLevel ?? null,
    });

    await this.rateLimiter.increment(user.id);
    const jobId = String(job._id);
    await this.aiWorkerService.enqueueJob(
      jobId,
      user.id,
      dto.subjectId ?? null,
      dto.chapterId ?? null,
    );

    return { jobId, status: 'queued' };
  }

  @Get('notes/jobs/:id')
  async getJob(@Param('id') id: string) {
    return this.aiJobsRepo.findById(id);
  }

  @Get('artifacts')
  async getArtifacts(
    @CurrentUser() user: CurrentUserPayload,
    @Query('subjectId') subjectId?: string,
    @Query('chapterId') chapterId?: string,
  ) {
    if (chapterId) {
      return this.aiArtifactsRepo.findByChapter(user.id, chapterId);
    }
    return this.aiArtifactsRepo.findBySubject(user.id, subjectId ?? '');
  }

  @Delete('artifacts/jobs/:jobId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteJobArtifacts(
    @CurrentUser() user: CurrentUserPayload,
    @Param('jobId') jobId: string,
  ): Promise<void> {
    const deletedCount = await this.aiArtifactsRepo.deleteByJob(user.id, jobId);
    if (deletedCount === 0) {
      throw new NotFoundException('Study pack not found.');
    }
  }
}
