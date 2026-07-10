import { MailMessage } from '../../../infrastructure/mailer/mailer.module';

/**
 * Builds the password-reset email. `resetUrl` is a ready-to-open link
 * (e.g. `zakerly://reset-password?token=...`) that opens the app.
 */
export function buildPasswordResetEmail(to: string, resetUrl: string): MailMessage {
  const text = [
    'Reset your Focaly password',
    '',
    'Open this link to choose a new password:',
    resetUrl,
    '',
    'This link expires in 1 hour.',
    "If you didn't request a password reset, you can safely ignore this email.",
  ].join('\n');

  const html = `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#1a1a1a">
    <h2 style="margin:0 0 8px">Reset your password</h2>
    <p style="margin:0 0 20px;color:#444">
      Tap the button below to set a new password for your Zakerly account.
    </p>
    <p style="text-align:center;margin:28px 0">
      <a href="${resetUrl}"
         style="background:#6C5CE7;color:#ffffff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:bold;display:inline-block">
        Reset my password
      </a>
    </p>
    <p style="margin:0 0 6px;color:#888;font-size:13px">
      If the button doesn't work, copy and paste this link:
    </p>
    <p style="word-break:break-all;font-size:12px;color:#6C5CE7;margin:0 0 20px">
      ${resetUrl}
    </p>
    <p style="color:#aaa;font-size:12px;margin:0">
      This link expires in 1 hour. If you didn't request a reset, you can ignore this email.
    </p>
  </div>`;

  return {
    to,
    subject: 'Reset your Focaly password',
    text,
    html,
  };
}
