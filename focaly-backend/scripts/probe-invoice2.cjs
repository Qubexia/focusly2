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
      merchant_order_id: 'inv2-' + Date.now(),
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

  const paymentToken = pkData.token;
  console.log('payment key response keys', Object.keys(pkData));

  const endpoints = [
    `https://accept.paymob.com/api/acceptance/payments/standalone?payment_token=${encodeURIComponent(paymentToken)}`,
    `https://accept.paymobsolutions.com/api/acceptance/payments/standalone?payment_token=${encodeURIComponent(paymentToken)}`,
  ];

  for (const url of endpoints) {
    const r = await fetch(url, { headers: { Accept: 'application/json' } });
    const text = await r.text();
    console.log('\n===', r.status, url.slice(0, 90));
    console.log(text.slice(0, 800));
  }

  // decode payment token like standalone does (base64)
  const decoded = Buffer.from(paymentToken, 'base64').toString('utf8');
  console.log('\ndecoded starts with', decoded.slice(0, 80));
  try {
    const inner = JSON.parse(decoded);
    console.log('inner keys', Object.keys(inner));
    if (inner.token) {
      const inv2 = await fetch(`https://accept.paymob.com/invoice2/${inner.token}`, {
        headers: { Accept: 'application/json' },
      });
      console.log('\ninvoice2 inner.token', inv2.status, (await inv2.text()).slice(0, 500));
    }
  } catch (e) {
    console.log('decode err', e.message);
  }
})();
