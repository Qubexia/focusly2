require('dotenv').config();

(async () => {
  const t = await fetch('https://accept.paymob.com/standalone/static/js/main.09e7a310.chunk.js').then(
    (r) => r.text(),
  );

  for (const needle of ['URLSearchParams', 'payment_token', 'query.payment', '?payment_token']) {
    let idx = 0;
    let n = 0;
    while (n < 2 && (idx = t.indexOf(needle, idx)) >= 0) {
      console.log('\n---', needle, n, '---');
      console.log(t.slice(idx, idx + 350));
      idx += needle.length;
      n++;
    }
  }

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
      merchant_order_id: 'analyze-' + Date.now(),
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
        email: 't@t.com',
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
  // Try register iframe
  const createIframe = await fetch('https://accept.paymob.com/api/acceptance/iframes', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + authToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ name: 'Focusly Checkout', description: 'Focusly mobile app' }),
  });
  console.log('\ncreate iframe', createIframe.status, await createIframe.text());

  // Try intention with card integration probe - list if any card integrations exist
  const secretKey = process.env.PAYMOB_SECRET_KEY.trim();
  const intention = await fetch('https://accept.paymob.com/v1/intention/', {
    method: 'POST',
    headers: {
      Authorization: 'Token ' + secretKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: 9900,
      currency: 'EGP',
      payment_methods: [5690496],
      items: [{ name: 'Test', amount: 9900, description: 't', quantity: 1 }],
      billing_data: {
        apartment: 'NA',
        first_name: 'T',
        last_name: 'U',
        street: 'NA',
        building: 'NA',
        phone_number: '+201000000000',
        country: 'EG',
        email: 't@t.com',
        floor: 'NA',
        state: 'NA',
        city: 'Cairo',
      },
    }),
  });
  console.log('\nintention', intention.status, (await intention.text()).slice(0, 300));
})();
