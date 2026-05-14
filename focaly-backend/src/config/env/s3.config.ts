import { registerAs } from '@nestjs/config';

export default registerAs('s3', () => ({
  bucket: process.env.S3_BUCKET ?? '',
  region: process.env.S3_REGION ?? 'us-east-1',
  endpoint: process.env.S3_ENDPOINT ?? '',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? '',
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? '',
}));
