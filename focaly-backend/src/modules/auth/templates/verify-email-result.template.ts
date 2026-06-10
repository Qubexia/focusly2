/**
 * Renders the HTML page shown after a user opens the verification link from
 * their email. Verification happens server-side, so this page works in any
 * browser (desktop or mobile) without the app installed. On mobile, the
 * "Open the app" button can hand off to the installed app via a deep link.
 */
export function buildVerifyResultPage(success: boolean, appOpenUrl: string): string {
  const accent = success ? '#6C5CE7' : '#E74C3C';
  const icon = success ? '&#10003;' : '&#33;';
  const title = success ? 'Email verified' : 'Verification failed';
  const message = success
    ? 'Your email address has been verified. You can return to the Zakerly app and continue.'
    : 'This verification link is invalid, has expired, or was already used. Please open the app and request a new verification email.';

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title} — Zakerly</title>
</head>
<body style="margin:0;background:#0f0f17;font-family:Arial,Helvetica,sans-serif;color:#1a1a1a">
  <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box">
    <div style="background:#ffffff;border-radius:20px;max-width:420px;width:100%;padding:36px 28px;text-align:center;box-shadow:0 20px 50px rgba(0,0,0,.35)">
      <div style="width:72px;height:72px;border-radius:50%;background:${accent};color:#fff;font-size:38px;line-height:72px;margin:0 auto 20px">${icon}</div>
      <h1 style="margin:0 0 10px;font-size:22px">${title}</h1>
      <p style="margin:0 0 26px;color:#555;font-size:15px;line-height:1.5">${message}</p>
      <a href="${appOpenUrl}"
         style="background:${accent};color:#fff;text-decoration:none;padding:14px 30px;border-radius:10px;font-weight:bold;display:inline-block">
        Open the app
      </a>
    </div>
  </div>
</body>
</html>`;
}
