import './dev-runtime-flags.cjs';
import 'dotenv/config';

async function main(): Promise<void> {
  const apiKey = process.env.PAYMOB_API_KEY ?? '';
  const integrationId = Number(process.env.PAYMOB_INTEGRATION_ID ?? 0);

  const auth = await fetch('https://accept.paymob.com/api/auth/tokens', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ api_key: apiKey }),
  }).then((r) => r.json());

  const order = await fetch('https://accept.paymob.com/api/ecommerce/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: auth.token,
      delivery_needed: false,
      amount_cents: 10000,
      currency: 'EGP',
      merchant_order_id: `probe-${Date.now()}`,
      items: [{ name: 't', amount_cents: 10000, quantity: 1, description: 't' }],
    }),
  }).then((r) => r.json());

  const pk = await fetch('https://accept.paymob.com/api/acceptance/payment_keys', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: auth.token,
      amount_cents: 10000,
      expiration: 3600,
      order_id: order.id,
      billing_data: {
        apartment: 'NA',
        email: 'test@test.com',
        floor: 'NA',
        first_name: 'T',
        street: 'NA',
        building: 'NA',
        phone_number: '+201000000000',
        shipping_method: 'PKG',
        postal_code: 'NA',
        city: 'Cairo',
        country: 'EG',
        last_name: 'U',
        state: 'NA',
      },
      currency: 'EGP',
      integration_id: integrationId,
    }),
  }).then((r) => r.json());

  const token = pk.token as string;
  console.log('payment_token length:', token?.length);

  const decoded = JSON.parse(Buffer.from(token.split('.')[1] ?? '', 'base64url').toString());
  console.log('decoded payload keys:', Object.keys(decoded));
  console.log('integration_id:', decoded.integration_id);
  console.log('gateway_type:', decoded.gateway_type);

  const urls = [
    `https://accept.paymob.com/standalone/?payment_token=${encodeURIComponent(token)}`,
    `https://accept.paymobsolutions.com/api/acceptance/iframes/1?payment_token=${encodeURIComponent(token)}`,
  ];

  for (const url of urls) {
    const res = await fetch(url.split('?')[0] + (url.includes('standalone') ? '/' : ''), {
      redirect: 'manual',
    }).catch(() => null);
    console.log('HEAD base', url.slice(0, 60), res?.status);
  }

  const standaloneHtml = await fetch('https://accept.paymob.com/standalone/').then((r) => r.text());
  const scriptMatch = standaloneHtml.match(/src="([^"]+)"/);
  console.log('standalone first script:', scriptMatch?.[1]);

  for (const host of ['https://flashjs.paymob.com/v1/paymob.js', 'https://accept.paymob.com']) {
    try {
      const r = await fetch(host, { method: 'HEAD' });
      console.log('reachable', host, r.status);
    } catch (e) {
      console.log('unreachable', host, e instanceof Error ? e.message : e);
    }
  }
}

void main();
