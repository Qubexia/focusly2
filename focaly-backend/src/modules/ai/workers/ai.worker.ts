import { createHash } from 'crypto';

import { DetectDocumentTextCommand, TextractClient } from '@aws-sdk/client-textract';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventBus } from '@nestjs/cqrs';
import { Job } from 'bullmq';
import OpenAI from 'openai';

import { QUEUE_AI } from '../../../infrastructure/queue/queue.constants';
import { AiJobCompletedEvent } from '../../../shared/events/ai-job-completed.event';
import { AiArtifactsRepository } from '../ai-artifacts.repository';
import { AiJobsRepository } from '../ai-jobs.repository';
import { AiSettingsService } from '../ai-settings.service';

interface AiJobData {
  jobId: string;
  userId: string;
  subjectId: string | null;
}

function asText(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return '';
}

@Processor(QUEUE_AI)
export class AiWorker extends WorkerHost {
  private readonly logger = new Logger(AiWorker.name);

  constructor(
    private readonly aiJobsRepo: AiJobsRepository,
    private readonly aiArtifactsRepo: AiArtifactsRepository,
    private readonly eventBus: EventBus,
    private readonly config: ConfigService,
    private readonly aiSettings: AiSettingsService,
  ) {
    super();
  }

  async process(job: Job<AiJobData>): Promise<void> {
    const { jobId, userId, subjectId } = job.data;

    await this.aiJobsRepo.updateStatus(jobId, 'processing', { startedAt: new Date() });

    try {
      if (!subjectId) {
        await this.aiJobsRepo.updateStatus(jobId, 'completed', {
          completedAt: new Date(),
          tokensIn: undefined,
          tokensOut: undefined,
        });
        this.eventBus.publish(new AiJobCompletedEvent(userId, jobId, '', []));
        return;
      }

      const aiJob = await this.aiJobsRepo.findById(jobId);
      if (!aiJob) {
        throw new Error(`AI job not found: ${jobId}`);
      }

      const imageKeys = aiJob.imageKeys ?? [];
      if (imageKeys.length === 0) {
        throw new Error('No image keys found for this job');
      }

      const aiSettings = await this.aiSettings.resolve();
      const textractRegion =
        this.config.get<string>('openai.textractRegion') ??
        this.config.get<string>('s3.region') ??
        'us-east-1';
      const s3Bucket = this.config.get<string>('s3.bucket') ?? '';

      if (!aiSettings.enabled) {
        throw new Error('AI features are currently disabled by the administrator.');
      }
      if (!aiSettings.apiKey) {
        throw new Error('OpenAI is not configured (set an API key in the admin dashboard).');
      }
      if (!s3Bucket) {
        throw new Error('S3 bucket is not configured (S3_BUCKET missing).');
      }

      const cacheHash = createHash('sha256').update(imageKeys.join('|')).digest('hex');
      await this.aiJobsRepo.updateStatus(jobId, 'processing', { ocrCacheHash: cacheHash });

      const ocrText = await this.extractOcrTextFromImages({
        imageKeys,
        bucket: s3Bucket,
        region: textractRegion,
      });

      const openai = new OpenAI({ apiKey: aiSettings.apiKey });

      const pack = await this.generateStudyPack({
        openai,
        model: aiSettings.model,
        temperature: aiSettings.temperature,
        systemPrompt: aiSettings.systemPrompt,
        ocrText,
      });

      // Summary
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        jobId,
        kind: 'summary',
        content: { text: pack.summary },
      });

      // Flashcards
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        jobId,
        kind: 'flashcards',
        content: { cards: pack.flashcards },
      });

      // Questions
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        jobId,
        kind: 'questions',
        content: { questions: pack.questions },
      });

      await this.aiJobsRepo.updateStatus(jobId, 'completed', {
        completedAt: new Date(),
        tokensIn: pack.tokensIn ?? undefined,
        tokensOut: pack.tokensOut ?? undefined,
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

  private async extractOcrTextFromImages(args: {
    imageKeys: string[];
    bucket: string;
    region: string;
  }): Promise<string> {
    // Textract can be slow; keep it simple/serial to avoid spiking concurrency.
    const client = new TextractClient({
      region: args.region,
      // Credentials are resolved from the runtime env (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / IAM role).
    });

    const parts: string[] = [];
    const keysToProcess = args.imageKeys.slice(0, 4); // limit for cost/latency

    for (const key of keysToProcess) {
      const res = await client.send(
        new DetectDocumentTextCommand({
          Document: {
            S3Object: {
              Bucket: args.bucket,
              Name: key,
            },
          },
        }),
      );

      const lines =
        res.Blocks?.filter((b) => b.BlockType === 'LINE' && (b.Text?.trim() ?? '') !== '') ?? [];
      const text = lines
        .map((l) => l.Text)
        .filter(Boolean)
        .join('\n');
      if (text.trim().length > 0) {
        parts.push(text);
      }
    }

    const joined = parts.join('\n\n');
    if (joined.trim().length === 0) {
      throw new Error('Textract returned empty OCR text.');
    }

    // Avoid huge prompts.
    return joined.slice(0, 40_000);
  }

  private async generateStudyPack(args: {
    openai: OpenAI;
    model: string;
    temperature: number;
    systemPrompt: string | null;
    ocrText: string;
  }): Promise<{
    summary: string;
    flashcards: Array<{ front: string; back: string }>;
    questions: Array<{ question: string; answer: string }>;
    tokensIn?: number;
    tokensOut?: number;
  }> {
    const completion = await args.openai.chat.completions.create({
      model: args.model,
      temperature: args.temperature,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content:
            args.systemPrompt && args.systemPrompt.trim().length > 0
              ? args.systemPrompt
              : 'You are a study assistant. You must output valid JSON that matches the requested schema only.',
        },
        {
          role: 'user',
          content: `Using the OCR text below, generate a compact study pack.

OCR TEXT:
${args.ocrText}

Return ONLY JSON with this schema:
{
  "summary": "string (max 800 chars)",
  "flashcards": [ { "front": "string", "back": "string" } ],
  "questions": [ { "question": "string", "answer": "string" } ]
}

Rules:
- summary <= 800 characters
- flashcards: exactly 6 items
- questions: exactly 5 items
- Use clear Arabic (or the same language as the OCR)`,
        },
      ],
    });

    const raw = completion.choices?.[0]?.message?.content ?? '{}';
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(raw) as Record<string, unknown>;
    } catch {
      // Defensive fallback: try to extract the first JSON object.
      const match = raw.match(/\{[\s\S]*\}/);
      parsed = match ? (JSON.parse(match[0]) as Record<string, unknown>) : {};
    }

    const summary = asText(parsed.summary).slice(0, 800);

    const flashcardsRaw = parsed.flashcards;
    const flashcards = Array.isArray(flashcardsRaw)
      ? flashcardsRaw
          .slice(0, 6)
          .map((item) => {
            const card = item as Record<string, unknown>;
            return {
              front: asText(card.front).trim(),
              back: asText(card.back).trim(),
            };
          })
          .filter((card) => card.front.length > 0 && card.back.length > 0)
      : [];

    const questionsRaw = parsed.questions;
    const questions = Array.isArray(questionsRaw)
      ? questionsRaw
          .slice(0, 5)
          .map((item) => {
            const question = item as Record<string, unknown>;
            return {
              question: asText(question.question).trim(),
              answer: asText(question.answer).trim(),
            };
          })
          .filter((item) => item.question.length > 0 && item.answer.length > 0)
      : [];

    const usage = completion.usage;
    return {
      summary,
      flashcards,
      questions,
      tokensIn: usage?.prompt_tokens,
      tokensOut: usage?.completion_tokens,
    };
  }
}
