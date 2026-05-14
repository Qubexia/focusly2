import { registerAs } from '@nestjs/config';

export default registerAs('openai', () => ({
  apiKey: process.env.OPENAI_API_KEY ?? '',
  textractRegion: process.env.AWS_TEXTRACT_REGION ?? '',
}));
