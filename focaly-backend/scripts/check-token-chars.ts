import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PaymobService } from '../src/modules/subscription/paymob.service';
import { UsersRepository } from '../src/modules/users/users.repository';

async function main(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const paymob = app.get(PaymobService);
    const users = app.get(UsersRepository);
    const user = await users.findActiveByEmail('abdelmottale3@gmail.com');
    if (!user) {
      throw new Error('user missing');
    }

    const result = await paymob.createPremiumCheckout(String(user._id), 'monthly');
    const url = result.checkoutUrl;
    const raw = url.split('payment_token=')[1] ?? '';
    const token = decodeURIComponent(raw);
    console.log('url length', url.length);
    console.log('token has +', token.includes('+'));
    console.log('token has /', token.includes('/'));
    console.log('token has =', token.includes('='));

    const standalone = await fetch(url, { headers: { Accept: 'application/json' } });
    const html = await standalone.text();
    console.log('standalone page', standalone.status, html.includes('id="root"'));

    const apiUrl = `https://accept.paymob.com/api/acceptance/standalone?payment_token=${encodeURIComponent(token)}`;
    const api = await fetch(apiUrl);
    console.log('standalone api', api.status, (await api.text()).slice(0, 120));
  } finally {
    await app.close();
  }
}

void main();
