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
import { AiFilesService } from '../ai-files.service';
import { AiJobsRepository } from '../ai-jobs.repository';
import { AiSettingsService } from '../ai-settings.service';

interface AiJobData {
  jobId: string;
  userId: string;
  subjectId: string | null;
  chapterId?: string | null;
}

interface StudyPack {
  summary: string;
  flashcards: Array<{ front: string; back: string }>;
  questions: Array<{ question: string; answer: string }>;
  tokensIn?: number;
  tokensOut?: number;
}

interface StudyConfig {
  cards: number;
  questions: number;
  summaryMaxChars: number;
  summaryGuide: string;
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
    private readonly aiFiles: AiFilesService,
    private readonly eventBus: EventBus,
    private readonly config: ConfigService,
    private readonly aiSettings: AiSettingsService,
  ) {
    super();
  }

  async process(job: Job<AiJobData>): Promise<void> {
    await this.runJob(job.data);
  }

  /**
   * Core job processing. Invoked by the BullMQ processor, or directly (inline)
   * when Redis/queues are disabled in local dev (FOCALY_DISABLE_REDIS=true).
   */
  async runJob(data: AiJobData): Promise<void> {
    const { jobId, userId, subjectId, chapterId = null } = data;

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
      const pdfKeys = aiJob.pdfKeys ?? [];
      if (imageKeys.length === 0 && pdfKeys.length === 0) {
        throw new Error('No image or PDF keys found for this job');
      }

      const aiSettings = await this.aiSettings.resolve();

      if (!aiSettings.enabled) {
        throw new Error('AI features are currently disabled by the administrator.');
      }

      const cacheHash = createHash('sha256')
        .update([...pdfKeys, ...imageKeys].join('|'))
        .digest('hex');
      await this.aiJobsRepo.updateStatus(jobId, 'processing', { ocrCacheHash: cacheHash });

      // User-selected analysis options (language + summary depth).
      const studyConfig = this.studyConfigFor(aiJob.detailLevel);
      const instruction = this.buildInstruction(aiJob.language, studyConfig);

      let pack: StudyPack;
      if (pdfKeys.length > 0) {
        // Gemini reads PDF files natively (text + scanned) — no OCR, no S3, and
        // no provider balance gate. The PDF bytes go straight to the model.
        const geminiApiKey = this.config.get<string>('openai.geminiApiKey') ?? '';
        const geminiModel = this.config.get<string>('openai.geminiModel') ?? 'gemini-2.5-flash';
        if (!geminiApiKey) {
          throw new Error('Gemini is not configured (set GEMINI_API_KEY).');
        }

        const files: string[] = [];
        for (const fileId of pdfKeys.slice(0, 3)) {
          const buffer = await this.aiFiles.read(fileId);
          files.push(buffer.toString('base64'));
        }

        pack = await this.generateStudyPackFromPdfsGemini({
          apiKey: geminiApiKey,
          model: geminiModel,
          temperature: aiSettings.temperature,
          systemPrompt: aiSettings.systemPrompt,
          pdfBase64List: files,
          instruction,
          config: studyConfig,
        });
      } else {
        // Images use AWS Textract OCR, then an OpenAI-compatible model.
        if (!aiSettings.apiKey) {
          throw new Error('OpenAI is not configured (set an API key in the admin dashboard).');
        }
        const usesCustomBaseUrl = aiSettings.baseUrl.length > 0;
        const openai = new OpenAI({
          apiKey: aiSettings.apiKey,
          baseURL: usesCustomBaseUrl ? aiSettings.baseUrl : undefined,
          defaultHeaders: usesCustomBaseUrl
            ? { 'HTTP-Referer': 'https://focaly.app', 'X-Title': 'Focaly' }
            : undefined,
        });

        const textractRegion =
          this.config.get<string>('openai.textractRegion') ??
          this.config.get<string>('s3.region') ??
          'us-east-1';
        const s3Bucket = this.config.get<string>('s3.bucket') ?? '';
        if (!s3Bucket) {
          throw new Error('S3 bucket is not configured (S3_BUCKET missing).');
        }

        const ocrText = (
          await this.extractOcrTextFromImages({
            imageKeys,
            bucket: s3Bucket,
            region: textractRegion,
          })
        ).slice(0, 40_000);
        if (ocrText.trim().length === 0) {
          throw new Error('Textract returned empty OCR text.');
        }

        pack = await this.generateStudyPack({
          openai,
          model: aiSettings.model,
          temperature: aiSettings.temperature,
          systemPrompt: aiSettings.systemPrompt,
          ocrText,
          jsonMode: !usesCustomBaseUrl,
          instruction,
          config: studyConfig,
        });
      }

      // Summary
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        chapterId,
        jobId,
        kind: 'summary',
        content: { text: pack.summary },
      });

      // Flashcards
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        chapterId,
        jobId,
        kind: 'flashcards',
        content: { cards: pack.flashcards },
      });

      // Questions
      await this.aiArtifactsRepo.create({
        userId,
        subjectId,
        chapterId,
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

    // Caller merges/truncates across sources; return the per-source text as-is.
    return parts.join('\n\n');
  }

  /** Shared schema + rules appended to every study-pack prompt. */
  /** Maps a requested detail level to concrete targets for the study pack. */
  private studyConfigFor(detailLevel: string | null | undefined): StudyConfig {
    switch ((detailLevel ?? 'medium').toLowerCase()) {
      case 'short':
        return {
          cards: 5,
          questions: 4,
          summaryMaxChars: 1500,
          summaryGuide: 'a concise overview of about 4–6 sentences capturing only the core ideas',
        };
      case 'long':
      case 'detailed':
        return {
          cards: 14,
          questions: 10,
          summaryMaxChars: 16000,
          summaryGuide:
            'a thorough, in-depth summary of several well-structured paragraphs that walks through every major section/topic in order, preserves important definitions, examples, formulas and conclusions, and uses short headings or bullet points where they improve clarity',
        };
      case 'medium':
      default:
        return {
          cards: 8,
          questions: 6,
          summaryMaxChars: 5000,
          summaryGuide:
            'a clear summary of about 2–4 well-developed paragraphs covering the main topics and the key supporting details',
        };
    }
  }

  private languageInstruction(language: string | null | undefined): string {
    switch ((language ?? 'auto').toLowerCase()) {
      case 'ar':
      case 'arabic':
        return 'Write ALL output (summary, flashcards, questions) in clear, fluent Arabic.';
      case 'en':
      case 'english':
        return 'Write ALL output (summary, flashcards, questions) in clear English.';
      case 'fr':
      case 'french':
        return 'Write ALL output (summary, flashcards, questions) in clear French.';
      default:
        return 'Write ALL output (summary, flashcards, questions) in the SAME language as the source material.';
    }
  }

  /** Builds the task instruction tailored to the requested language + depth. */
  private buildInstruction(language: string | null | undefined, config: StudyConfig): string {
    return `Produce a study pack as a JSON object with exactly this schema:
{
  "summary": "string",
  "flashcards": [ { "front": "string", "back": "string" } ],
  "questions": [ { "question": "string", "answer": "string" } ]
}

Requirements:
- summary: ${config.summaryGuide}. Scale the depth and length to the material — a longer or denser document deserves a longer, richer summary. Structure it with short paragraphs separated by blank lines and, where helpful, simple "- " bullet lines. Use plain text only (no markdown symbols like **, ##, or backticks).
- flashcards: around ${config.cards} high-quality cards on the most important concepts (definitions, key facts, cause/effect, formulas). "front" is a clear question/prompt, "back" is a precise, self-contained answer.
- questions: around ${config.questions} exam-style practice questions, each with a correct and complete answer.
- ${this.languageInstruction(language)}
- Base everything ONLY on the provided material; never invent facts. If the material is short, still produce a useful pack at an appropriate (smaller) size.

Return ONLY the JSON object — no markdown code fences, no commentary.`;
  }

  private systemPromptOrDefault(systemPrompt: string | null): string {
    return systemPrompt && systemPrompt.trim().length > 0
      ? systemPrompt
      : [
          'You are an expert study assistant that turns lecture notes, slides and documents into high-quality study material.',
          'You write accurate, well-organized and pedagogically useful summaries, flashcards and practice questions, and you preserve the important details of the source.',
          'You always respond with a single valid JSON object that matches the requested schema — no markdown code fences around the JSON, no extra commentary.',
        ].join(' ');
  }

  /** Generates a study pack from already-extracted OCR text (image path). */
  private async generateStudyPack(args: {
    openai: OpenAI;
    model: string;
    temperature: number;
    systemPrompt: string | null;
    ocrText: string;
    jsonMode: boolean;
    instruction: string;
    config: StudyConfig;
  }): Promise<StudyPack> {
    const completion = await args.openai.chat.completions.create({
      model: args.model,
      temperature: args.temperature,
      ...(args.jsonMode ? { response_format: { type: 'json_object' as const } } : {}),
      messages: [
        { role: 'system', content: this.systemPromptOrDefault(args.systemPrompt) },
        {
          role: 'user',
          content: `Use the OCR text below as the source material.

OCR TEXT:
${args.ocrText}

${args.instruction}`,
        },
      ],
    });

    const raw = completion.choices?.[0]?.message?.content ?? '{}';
    const usage = completion.usage;
    return this.parseStudyPackFromRaw(raw, args.config, {
      tokensIn: usage?.prompt_tokens,
      tokensOut: usage?.completion_tokens,
    });
  }

  /**
   * Generates a study pack directly from PDF file(s) using Google Gemini, which
   * ingests PDFs natively (no OCR, no provider balance gate). The PDF bytes are
   * sent inline as base64 to the generateContent endpoint.
   */
  private async generateStudyPackFromPdfsGemini(args: {
    apiKey: string;
    model: string;
    temperature: number;
    systemPrompt: string | null;
    pdfBase64List: string[];
    instruction: string;
    config: StudyConfig;
  }): Promise<StudyPack> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(
      args.model,
    )}:generateContent`;

    const parts: unknown[] = [
      {
        text: `Read the attached PDF document(s) as the source material, then complete the task.

${args.instruction}`,
      },
      ...args.pdfBase64List.map((data) => ({
        inline_data: { mime_type: 'application/pdf', data },
      })),
    ];

    const body = {
      systemInstruction: { parts: [{ text: this.systemPromptOrDefault(args.systemPrompt) }] },
      contents: [{ role: 'user', parts }],
      generationConfig: {
        temperature: args.temperature,
        responseMimeType: 'application/json',
        maxOutputTokens: 8192,
      },
    };

    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': args.apiKey },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const detail = await res.text();
      throw new Error(`Gemini request failed (${res.status}): ${detail.slice(0, 300)}`);
    }

    const json = (await res.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      usageMetadata?: { promptTokenCount?: number; candidatesTokenCount?: number };
    };

    const raw =
      json.candidates?.[0]?.content?.parts
        ?.map((p) => p.text ?? '')
        .join('')
        .trim() ?? '';
    if (raw.length === 0) {
      throw new Error('Gemini returned an empty response for the PDF.');
    }

    return this.parseStudyPackFromRaw(raw, args.config, {
      tokensIn: json.usageMetadata?.promptTokenCount,
      tokensOut: json.usageMetadata?.candidatesTokenCount,
    });
  }

  /** Parses (and defensively repairs) the JSON study pack from a raw string. */
  private parseStudyPackFromRaw(
    raw: string,
    config: StudyConfig,
    usage: { tokensIn?: number; tokensOut?: number },
  ): StudyPack {
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(raw) as Record<string, unknown>;
    } catch {
      // Defensive fallback: try to extract the first JSON object.
      const match = raw.match(/\{[\s\S]*\}/);
      parsed = match ? (JSON.parse(match[0]) as Record<string, unknown>) : {};
    }

    const summary = asText(parsed.summary).slice(0, config.summaryMaxChars);

    // Allow a little headroom over the target counts in case the model is generous.
    const maxCards = config.cards + 4;
    const maxQuestions = config.questions + 4;

    const flashcardsRaw = parsed.flashcards;
    const flashcards = Array.isArray(flashcardsRaw)
      ? flashcardsRaw
          .slice(0, maxCards)
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
          .slice(0, maxQuestions)
          .map((item) => {
            const question = item as Record<string, unknown>;
            return {
              question: asText(question.question).trim(),
              answer: asText(question.answer).trim(),
            };
          })
          .filter((item) => item.question.length > 0 && item.answer.length > 0)
      : [];

    return {
      summary,
      flashcards,
      questions,
      tokensIn: usage.tokensIn,
      tokensOut: usage.tokensOut,
    };
  }
}
