import './dev-runtime-flags.cjs';
import { VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { PaymobService } from '../src/modules/subscription/paymob.service';
import { UsersRepository } from '../src/modules/users/users.repository';

async function main(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false });
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  await app.listen(5055, '127.0.0.1');
  try {
    const paymob = app.get(PaymobService);
    const users = app.get(UsersRepository);
    const user = await users.findActiveByEmail('abdelmottale3@gmail.com');
    if (!user) throw new Error('user missing');

    const result = await paymob.createPremiumCheckout(
      String(user._id),
      'monthly',
      'http://127.0.0.1:5055',
    );
    const sessionId = result.checkoutUrl.split('/open/')[1];
    const config = await fetch('http://127.0.0.1:5055/v1/subscription/paymob/config-urls');
    console.log('config-urls', config.status);

    const page = await fetch(`http://127.0.0.1:5055/v1/subscription/paymob/open/${sessionId}`);
    const html = await page.text();
    console.log('page', page.status, html.includes('pay-form'), html.includes('ادفع الآن'));

    const pay = await fetch(`http://127.0.0.1:5055/v1/subscription/paymob/open/${sessionId}/pay`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Test User',
        number: '4987654321098769',
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123',
      }),
    });
    console.log('pay', pay.status, (await pay.text()).slice(0, 200));
  } finally {
    await app.close();
  }
}

void main();
