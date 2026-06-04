require('dotenv').config();

(async () => {
  const apiKey = process.env.PAYMOB_API_KEY.trim();
  const { token: authToken } = await fetch('https://accept.paymob.com/api/auth/tokens', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ api_key: apiKey }),
  }).then((r) => r.json());

  const order = await fetch('https://accept.paymob.com/api/ecommerce/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: authToken,
      delivery_needed: false,
      amount_cents: 9900,
      currency: 'EGP',
      merchant_order_id: 'std-' + Date.now(),
      items: [],
    }),
  }).then((r) => r.json());

  const pkData = await fetch('https://accept.paymob.com/api/acceptance/payment_keys', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: authToken,
      amount_cents: 9900,
      expiration: 3600,
      order_id: order.id,
      billing_data: {
        first_name: 'T',
        last_name: 'U',
        phone_number: '+201000000000',
        email: 'abdelmottale3@gmail.com',
        country: 'EG',
        city: 'Cairo',
        street: 'NA',
        building: 'NA',
        floor: 'NA',
        apartment: 'NA',
      },
      currency: 'EGP',
      integration_id: 5690496,
    }),
  }).then((r) => r.json());

  const pt = pkData.token;
  const urls = [
    `https://accept.paymob.com/api/acceptance/standalone?payment_token=${encodeURIComponent(pt)}`,
    `https://accept.paymobsolutions.com/api/acceptance/standalone?payment_token=${encodeURIComponent(pt)}`,
  ];

  for (const url of urls) {
    const r = await fetch(url, { headers: { Accept: 'application/json' } });
    const text = await r.text();
    console.log('\n===', r.status, url.split('?')[0]);
    console.log(text.slice(0, 1200));
  }
})();
