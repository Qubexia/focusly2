import { Module, Global, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

export interface MailMessage {
  to: string;
  subject: string;
  text?: string;
  html?: string;
}

export interface Mailer {
  send(message: MailMessage): Promise<void>;
}

/**
 * Fallback used in dev / when SMTP credentials are absent. It only logs the
 * message so the app can boot and flows can run without a real mail server.
 */
class ConsoleMailer implements Mailer {
  private readonly logger = new Logger(ConsoleMailer.name);

  send(message: MailMessage): Promise<void> {
    this.logger.log(`[mail:console] → ${message.to} | ${message.subject}`);
    if (message.text) {
      this.logger.debug(`[mail:console] body: ${message.text}`);
    }
    return Promise.resolve();
  }
}

/** Real transport backed by nodemailer over SMTP. */
class SmtpMailer implements Mailer {
  private readonly logger = new Logger(SmtpMailer.name);

  constructor(
    private readonly transport: nodemailer.Transporter,
    private readonly from: string,
  ) {}

  async send(message: MailMessage): Promise<void> {
    try {
      await this.transport.sendMail({
        from: this.from,
        to: message.to,
        subject: message.subject,
        text: message.text,
        html: message.html,
      });
      this.logger.log(`[mail:smtp] sent → ${message.to} | ${message.subject}`);
    } catch (err: unknown) {
      const reason = err instanceof Error ? err.message : String(err);
      this.logger.error(`[mail:smtp] failed → ${message.to}: ${reason}`);
      throw err;
    }
  }
}

export const MAILER = Symbol('MAILER');

@Global()
@Module({
  providers: [
    {
      provide: MAILER,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Mailer => {
        const logger = new Logger('MailerModule');
        const host = config.get<string>('mailer.smtp.host') ?? '';
        const port = config.get<number>('mailer.smtp.port') ?? 587;
        const user = config.get<string>('mailer.smtp.user') ?? '';
        const pass = config.get<string>('mailer.smtp.pass') ?? '';
        const from = config.get<string>('mailer.from') ?? 'Focaly <noreply@focaly.app>';

        if (!host || !user || !pass) {
          logger.warn(
            'SMTP credentials are missing (SMTP_HOST/SMTP_USER/SMTP_PASS). ' +
              'Falling back to console mailer; no emails will be delivered.',
          );
          return new ConsoleMailer();
        }

        const transport = nodemailer.createTransport({
          host,
          port,
          // 465 = implicit TLS; 587/others use STARTTLS upgrade.
          secure: port === 465,
          auth: { user, pass },
        });

        logger.log(`SMTP mailer active via ${host}:${port} (from: ${from}).`);
        return new SmtpMailer(transport, from);
      },
    },
  ],
  exports: [MAILER],
})
export class MailerModule {}
