import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  env: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 3000),
  logLevel: process.env.LOG_LEVEL ?? 'info',
  corsOrigins: (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),
  swagger: {
    user: process.env.SWAGGER_USER ?? '',
    pass: process.env.SWAGGER_PASS ?? '',
  },
  // Full base of the web email-verification endpoint that the email links to.
  // Empty -> falls back to http://localhost:<port>/v1/auth/verify-email.
  // Dev (device): set to your PC LAN IP. Prod: your public HTTPS host.
  verifyEmailUrl: process.env.APP_VERIFY_EMAIL_URL ?? '',
  // Deep link used by the "Open the app" button on the verification result page.
  appOpenUrl: process.env.APP_OPEN_URL ?? 'zakerly://login',
}));
