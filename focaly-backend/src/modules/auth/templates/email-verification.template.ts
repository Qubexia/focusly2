import { MailMessage } from '../../../infrastructure/mailer/mailer.module';

export function buildVerificationEmail(to: string, token: string): MailMessage {
  return {
    to,
    subject: 'Verify your Focaly email',
    text: `Use this token to verify your email: ${token}`,
    html: `<p>Use this token to verify your email:</p><pre>${token}</pre>`,
  };
}
