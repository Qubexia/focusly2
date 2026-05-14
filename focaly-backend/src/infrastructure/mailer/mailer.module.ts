import { Module, Global, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface MailMessage {
  to: string;
  subject: string;
  text?: string;
  html?: string;
}

export interface Mailer {
  send(message: MailMessage): Promise<void>;
}

class ConsoleMailer implements Mailer {
  private readonly logger = new Logger(ConsoleMailer.name);

  async send(message: MailMessage): Promise<void> {
    this.logger.log(`[mail] → ${message.to} | ${message.subject}`);
  }
}

export const MAILER = Symbol('MAILER');

@Global()
@Module({
  providers: [
    {
      provide: MAILER,
      inject: [ConfigService],
      useFactory: (_config: ConfigService): Mailer => {
        // Real SMTP/SES transports land in the auth module's mailer wiring;
        // Phase 2 ships a console mailer so boot works without SMTP creds.
        return new ConsoleMailer();
      },
    },
  ],
  exports: [MAILER],
})
export class MailerModule {}
