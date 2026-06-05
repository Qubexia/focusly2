import { registerAs } from '@nestjs/config';

export default registerAs('openai', () => ({
  apiKey: process.env.OPENAI_API_KEY ?? '',
  // OpenAI-compatible base URL. Set to https://openrouter.ai/api/v1 to use OpenRouter.
  baseUrl: process.env.OPENAI_BASE_URL ?? '',
  textractRegion: process.env.AWS_TEXTRACT_REGION ?? '',
  // Google Gemini — reads PDFs natively (used for the PDF study-pack flow).
  // Requires GEMINI_API_KEY in the environment (loaded at process startup).
  geminiApiKey: process.env.GEMINI_API_KEY ?? '',
  geminiModel: process.env.GEMINI_MODEL ?? 'gemini-2.5-flash',
}));
