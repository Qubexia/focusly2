import './dev-runtime-flags.cjs';
import 'dotenv/config';
import { VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PaymobService } from '../src/modules/subscription/paymob.service';
import { SubscriptionsRepository } from '../src/modules/subscription/subscriptions.repository';
import { UsersRepository } from '../src/modules/users/users.repository';

const TEST_CARD = {
  name: 'Test Account',
  number: '4111111111111111',
  expiryMonth: '01',
  expiryYear: '39',
  cvv: '123',
};

async function main(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  const port = 5057;
  await app.listen(port, '0.0.0.0');

  try {
    const paymob = app.get(PaymobService);
    const users = app.get(UsersRepository);
    const subs = app.get(SubscriptionsRepository);

    const user =
      (await users.findActiveByEmail('abdelmottale3@gmail.com')) ??
      (await users.findActiveByEmail('test@Zakerly.app'));
    if (!user) {
      console.error('✗ No test user. Register once, then rerun.');
      process.exitCode = 1;
      return;
    }

    const userId = String(user._id);
    const base = `http://127.0.0.1:${port}`;
    console.log('User:', user.email, userId);

    const before = await subs.findByUserId(userId);
    console.log('Premium before:', before?.status ?? 'none', before?.currentPeriodEnd ?? '—');

    console.log('\n1) Create checkout session…');
    const checkout = await paymob.createPremiumCheckout(userId, 'monthly', base, base);
    console.log('   checkoutUrl:', checkout.checkoutUrl);
    console.log('   amount:', checkout.amountCents / 100, checkout.currency);

    const sessionId = checkout.checkoutUrl.split('/open/')[1]?.split('/')[0] ?? '';
    if (!sessionId) {
      console.error('✗ Could not parse session id from checkout URL');
      process.exitCode = 1;
      return;
    }

    console.log('\n2) Load hosted checkout page…');
    const pageRes = await fetch(`${base}/v1/subscription/paymob/open/${sessionId}`);
    const html = await pageRes.text();
    console.log('   page status:', pageRes.status, 'has form:', html.includes('pay-form'));

    console.log('\n3) Submit Visa test card…');
    const payRes = await fetch(`${base}/v1/subscription/paymob/open/${sessionId}/pay`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(TEST_CARD),
    });
    const payBody = (await payRes.json()) as Record<string, unknown>;
    console.log('   pay status:', payRes.status);
    console.log('   pay response:', JSON.stringify(payBody, null, 2).slice(0, 1200));

    if (payBody.redirectUrl && typeof payBody.redirectUrl === 'string') {
      console.log('\n4) Follow Paymob redirect…');
      const redirectRes = await fetch(payBody.redirectUrl, { redirect: 'manual' });
      const loc = redirectRes.headers.get('location');
      console.log('   redirect status:', redirectRes.status);
      if (loc) console.log('   location:', loc.slice(0, 200));
      const redirectText = redirectRes.status === 200 ? await redirectRes.text() : '';
      if (redirectText.includes('success')) {
        const m = redirectText.match(/success=(true|false)/);
        if (m) console.log('   success param:', m[1]);
      }
    }

    const after = await subs.findByUserId(userId);
    console.log(
      '\n5) Premium after (may need webhook):',
      after?.status ?? 'none',
      after?.currentPeriodEnd ?? '—',
    );

    const paid =
      payBody.success === true ||
      (typeof payBody.message === 'string' && payBody.message.includes('successful'));
    if (paid || after?.status === 'active') {
      console.log('\n✓ Payment flow completed (card accepted or premium active).');
    } else if (payBody.redirectUrl) {
      console.log(
        '\n◐ Card submitted — completed via Paymob redirect (check success in redirect URL).',
      );
      console.log(
        '  Premium activates when Paymob webhook reaches your server (PUBLIC_API_BASE_URL).',
      );
    } else {
      console.log('\n✗ Payment did not succeed. See pay response above.');
      process.exitCode = 1;
    }
  } finally {
    await app.close();
  }
}

void main();
