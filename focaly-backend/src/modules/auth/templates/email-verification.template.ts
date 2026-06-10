import { MailMessage } from '../../../infrastructure/mailer/mailer.module';

/**
 * Builds the verification email. `verifyUrl` is a ready-to-open link
 * (e.g. `zakerly://verify-email?token=...`) that opens the app and verifies
 * the account. A plain-text copy is included for clients that strip the button.
 */
export function buildVerificationEmail(to: string, verifyUrl: string): MailMessage {
  const text = [
    'Welcome to Zakerly!',
    '',
    'Verify your email by opening this link:',
    verifyUrl,
    '',
    'This link expires in 1 hour.',
    "If you didn't create a Zakerly account, you can safely ignore this email.",
  ].join('\n');

  const html = `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#1a1a1a">
    <h2 style="margin:0 0 8px">Verify your email</h2>
    <p style="margin:0 0 20px;color:#444">
      Tap the button below to verify your Zakerly account and get started.
    </p>
    <p style="text-align:center;margin:28px 0">
      <a href="${verifyUrl}"
         style="background:#6C5CE7;color:#ffffff;text-decoration:none;padding:14px 28px;border-radius:10px;font-weight:bold;display:inline-block">
        Verify my email
      </a>
    </p>
    <p style="margin:0 0 6px;color:#888;font-size:13px">
      If the button doesn't work, copy and paste this link:
    </p>
    <p style="word-break:break-all;font-size:12px;color:#6C5CE7;margin:0 0 20px">
      ${verifyUrl}
    </p>
    <p style="color:#aaa;font-size:12px;margin:0">
      This link expires in 1 hour. If you didn't create a Zakerly account, you can ignore this email.
    </p>
  </div>`;

  return {
    to,
    subject: 'Verify your Zakerly email',
    text,
    html,
  };
}
