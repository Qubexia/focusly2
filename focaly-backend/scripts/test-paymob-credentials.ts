import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PaymobService } from '../src/modules/subscription/paymob.service';
import { UsersRepository } from '../src/modules/users/users.repository';

/**
 * Quick Paymob checkout smoke test (uses legacy fallback for VPC integrations).
 *
 *   npm run paymob:test
 */
async function main(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const paymob = app.get(PaymobService);
    const users = app.get(UsersRepository);

    const user =
      (await users.findActiveByEmail('abdelmottale3@gmail.com')) ??
      (await users.findActiveByEmail('test@focusly.app'));

    if (!user) {
      console.error('No test user found. Register/login once, then rerun npm run paymob:test.');
      process.exitCode = 1;
      return;
    }

    const result = await paymob.createPremiumCheckout(String(user._id), 'monthly');
    console.log('✓ Paymob checkout OK');
    console.log('  specialReference:', result.specialReference);
    console.log('  checkoutUrl:', result.checkoutUrl);
  } catch (error) {
    console.error('✗ Paymob checkout failed:', error instanceof Error ? error.message : error);
    process.exitCode = 1;
  } finally {
    await app.close();
  }
}

void main();
