import { registerAs } from '@nestjs/config';

export default registerAs('mailer', () => ({
  provider: process.env.MAIL_PROVIDER ?? 'console',
  from:
    process.env.MAIL_FROM ??
    process.env.SMTP_FROM ??
    process.env.SMTP_USER ??
    'Focaly <noreply@focaly.app>',
  smtp: {
    host: process.env.SMTP_HOST ?? '',
    port: Number(process.env.SMTP_PORT ?? 587),
    user: process.env.SMTP_USER ?? '',
    pass: process.env.SMTP_PASS ?? '',
  },
}));
