import { registerAs } from '@nestjs/config';

export default registerAs('jwt', () => ({
  privateKey: (process.env.JWT_PRIVATE_KEY ?? '').replace(/\\n/g, '\n'),
  publicKey: (process.env.JWT_PUBLIC_KEY ?? '').replace(/\\n/g, '\n'),
  accessTtlSeconds: Number(process.env.JWT_ACCESS_TTL ?? 900),
  refreshTtlSeconds: Number(process.env.JWT_REFRESH_TTL ?? 2_592_000),
  emailTokenSecret: process.env.EMAIL_TOKEN_SECRET ?? '',
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
}));
