import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import OpenAI from 'openai';

import { AiSetting, AiSettingDocument } from './schemas/ai-setting.schema';

const SINGLETON_KEY = 'global';
const DEFAULT_MODEL = 'gpt-4o-mini';
const DEFAULT_TEMPERATURE = 0.2;

export interface ResolvedAiSettings {
  enabled: boolean;
  apiKey: string;
  model: string;
  temperature: number;
  systemPrompt: string | null;
}

export interface MaskedAiSettings {
  enabled: boolean;
  apiKeySet: boolean;
  apiKeyPreview: string | null;
  apiKeySource: 'database' | 'env' | 'none';
  model: string;
  temperature: number;
  systemPrompt: string | null;
  updatedAt: Date | null;
}

export interface UpdateAiSettingsInput {
  enabled?: boolean;
  apiKey?: string; // empty string clears the stored key (falls back to env)
  model?: string;
  temperature?: number;
  systemPrompt?: string | null;
}

@Injectable()
export class AiSettingsService {
  constructor(
    @InjectModel(AiSetting.name) private readonly model: Model<AiSettingDocument>,
    private readonly config: ConfigService,
  ) {}

  private async getOrCreate(): Promise<AiSetting> {
    const doc = await this.model
      .findOneAndUpdate(
        { key: SINGLETON_KEY },
        { $setOnInsert: { key: SINGLETON_KEY } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      )
      .lean<AiSetting>()
      .exec();
    if (!doc) {
      // upsert guarantees a row; this only guards against a race on first write.
      throw new Error('Failed to initialise AI settings.');
    }
    return doc;
  }

  private envApiKey(): string {
    return this.config.get<string>('openai.apiKey') ?? '';
  }

  private envModel(): string {
    return process.env.OPENAI_MODEL ?? DEFAULT_MODEL;
  }

  /** Effective settings used by the worker (DB value, else env fallback). */
  async resolve(): Promise<ResolvedAiSettings> {
    const doc = await this.getOrCreate();
    return {
      enabled: doc.enabled,
      apiKey: doc.apiKey && doc.apiKey.length > 0 ? doc.apiKey : this.envApiKey(),
      model: doc.model && doc.model.length > 0 ? doc.model : this.envModel(),
      temperature: typeof doc.temperature === 'number' ? doc.temperature : DEFAULT_TEMPERATURE,
      systemPrompt: doc.systemPrompt,
    };
  }

  /** Settings for the admin UI — never exposes the raw key. */
  async masked(): Promise<MaskedAiSettings> {
    const doc = await this.getOrCreate();
    const dbKey = doc.apiKey ?? '';
    const envKey = this.envApiKey();
    const effectiveKey = dbKey.length > 0 ? dbKey : envKey;
    const source: MaskedAiSettings['apiKeySource'] =
      dbKey.length > 0 ? 'database' : envKey.length > 0 ? 'env' : 'none';

    return {
      enabled: doc.enabled,
      apiKeySet: effectiveKey.length > 0,
      apiKeyPreview: effectiveKey ? maskKey(effectiveKey) : null,
      apiKeySource: source,
      model: doc.model && doc.model.length > 0 ? doc.model : this.envModel(),
      temperature: doc.temperature ?? DEFAULT_TEMPERATURE,
      systemPrompt: doc.systemPrompt,
      updatedAt: doc.updatedAt ?? null,
    };
  }

  async update(input: UpdateAiSettingsInput): Promise<MaskedAiSettings> {
    const set: Record<string, unknown> = {};
    if (input.enabled !== undefined) set.enabled = input.enabled;
    if (input.model !== undefined) set.model = input.model.trim() || null;
    if (input.temperature !== undefined) set.temperature = input.temperature;
    if (input.systemPrompt !== undefined) {
      set.systemPrompt =
        input.systemPrompt && input.systemPrompt.trim() ? input.systemPrompt : null;
    }
    if (input.apiKey !== undefined) {
      // Empty string => clear stored key (fall back to env). Non-empty => set.
      set.apiKey = input.apiKey.trim().length > 0 ? input.apiKey.trim() : null;
    }

    await this.model
      .findOneAndUpdate(
        { key: SINGLETON_KEY },
        { $set: set, $setOnInsert: { key: SINGLETON_KEY } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      )
      .exec();

    return this.masked();
  }

  /** Validate an API key by hitting OpenAI. Uses the provided key, else the stored one. */
  async testConnection(apiKey?: string): Promise<{ ok: boolean; model?: string; error?: string }> {
    const resolved = await this.resolve();
    const key = apiKey && apiKey.trim().length > 0 ? apiKey.trim() : resolved.apiKey;
    if (!key) {
      return { ok: false, error: 'No API key configured.' };
    }

    try {
      const client = new OpenAI({ apiKey: key, timeout: 10_000, maxRetries: 0 });
      await client.models.list();
      return { ok: true, model: resolved.model };
    } catch (err) {
      return { ok: false, error: err instanceof Error ? err.message : 'Connection failed.' };
    }
  }
}

function maskKey(key: string): string {
  if (key.length <= 8) return '••••';
  return `${key.slice(0, 3)}••••${key.slice(-4)}`;
}
