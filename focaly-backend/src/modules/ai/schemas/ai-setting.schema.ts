import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type AiSettingDocument = HydratedDocument<AiSetting>;

/** Singleton document holding admin-configurable AI settings. */
@Schema({ timestamps: true, collection: 'ai_settings' })
export class AiSetting {
  /** Fixed key so there is always exactly one settings row. */
  @Prop({ type: String, required: true, unique: true, default: 'global' })
  key!: string;

  @Prop({ type: Boolean, default: true })
  enabled!: boolean;

  /** OpenAI API key. Null means "fall back to the OPENAI_API_KEY env var". */
  @Prop({ type: String, default: null })
  apiKey!: string | null;

  /**
   * OpenAI-compatible base URL (e.g. https://openrouter.ai/api/v1 for OpenRouter).
   * Null falls back to the OPENAI_BASE_URL env var (empty = official OpenAI API).
   */
  @Prop({ type: String, default: null })
  baseUrl!: string | null;

  /** Model id, e.g. gpt-4o-mini or moonshotai/kimi-k2.6:free. Null falls back to env/default. */
  @Prop({ type: String, default: null })
  model!: string | null;

  @Prop({ type: Number, default: 0.2, min: 0, max: 2 })
  temperature!: number;

  /** Optional system prompt override for the study-pack generator. */
  @Prop({ type: String, default: null })
  systemPrompt!: string | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const AiSettingSchema = SchemaFactory.createForClass(AiSetting);
