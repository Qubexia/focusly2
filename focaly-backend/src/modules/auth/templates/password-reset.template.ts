import { MailMessage } from '../../../infrastructure/mailer/mailer.module';

/**
 * Builds the password-reset email containing a one-time code (OTP).
 */
export function buildPasswordResetEmail(to: string, otp: string): MailMessage {
  const text = [
    'Reset your Focaly password',
    '',
    `Your verification code is: ${otp}`,
    '',
    'This code expires in 10 minutes.',
    "If you didn't request a password reset, you can safely ignore this email.",
  ].join('\n');

  const html = `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#1a1a1a">
    <h2 style="margin:0 0 8px">Reset your password</h2>
    <p style="margin:0 0 20px;color:#444">
      Use this code in the Zakerly app to set a new password for your account.
    </p>
    <p style="text-align:center;margin:28px 0">
      <span style="background:#F4F2FF;color:#6C5CE7;letter-spacing:6px;padding:16px 24px;border-radius:12px;font-weight:bold;font-size:28px;display:inline-block">
        ${otp}
      </span>
    </p>
    <p style="color:#aaa;font-size:12px;margin:0">
      This code expires in 10 minutes. If you didn't request a reset, you can ignore this email.
    </p>
  </div>`;

  return {
    to,
    subject: 'Your Focaly password reset code',
    text,
    html,
  };
}
