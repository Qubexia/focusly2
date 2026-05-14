import { MailMessage } from '../../../infrastructure/mailer/mailer.module';

export function buildPasswordResetEmail(to: string, token: string): MailMessage {
  return {
    to,
    subject: 'Reset your Focaly password',
    text: `Use this token to reset your password: ${token}`,
    html: `<p>Use this token to reset your password:</p><pre>${token}</pre>`,
  };
}
