import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PlatformSettingsService } from '../src/modules/platform-settings/platform-settings.service';

/**
 * Turn premium gating on or off without opening the admin dashboard.
 * While it is off every authenticated user gets the premium features for free.
 *
 *   npm run premium-gating -- on
 *   npm run premium-gating -- off
 */
async function main(): Promise<void> {
  const arg = (process.argv[2] ?? '').toLowerCase();
  if (arg !== 'on' && arg !== 'off') {
    console.error('Usage: npm run premium-gating -- <on|off>');
    process.exitCode = 1;
    return;
  }

  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const settings = app.get(PlatformSettingsService);
    const result = await settings.update({ premiumGatingEnabled: arg === 'on' });
    console.log(
      result.premiumGatingEnabled
        ? '✓ Premium gating is ENFORCED — only paying users get premium features.'
        : '✓ Premium gating is DISABLED — every user gets premium features for free.',
    );
  } finally {
    await app.close();
  }
}

void main();
