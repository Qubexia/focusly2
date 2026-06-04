require('dotenv').config();
const apiKey = process.env.PAYMOB_API_KEY.trim();
const pk = process.env.PAYMOB_PUBLIC_KEY.trim();

(async () => {
  const { token } = await (
    await fetch('https://accept.paymob.com/api/auth/tokens', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: apiKey }),
    })
  ).json();
  const order = await (
    await fetch('https://accept.paymob.com/api/ecommerce/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: token,
        delivery_needed: false,
        amount_cents: 9900,
        currency: 'EGP',
        merchant_order_id: 'probe-' + Date.now(),
        items: [],
      }),
    })
  ).json();
  const pkData = await (
    await fetch('https://accept.paymob.com/api/acceptance/payment_keys', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: token,
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
    })
  ).json();
  const pt = pkData.token;
  const urls = [
    ['standalone', `https://accept.paymob.com/standalone/?payment_token=${encodeURIComponent(pt)}`],
    [
      'standalone+pk',
      `https://accept.paymob.com/standalone/?publicKey=${encodeURIComponent(pk)}&payment_token=${encodeURIComponent(pt)}`,
    ],
    [
      'paymob iframe 947590',
      `https://accept.paymob.com/api/acceptance/iframes/947590?payment_token=${encodeURIComponent(pt)}`,
    ],
    [
      'solutions iframe 947590',
      `https://accept.paymobsolutions.com/api/acceptance/iframes/947590?payment_token=${encodeURIComponent(pt)}`,
    ],
  ];
  for (const [label, u] of urls) {
    const r = await fetch(u, { redirect: 'manual' });
    const html = r.status === 200 ? await r.text() : '';
    const scripts = html.match(/src="[^"]+"/g) || [];
    console.log('\n===', label, r.status, 'len', html.length);
    console.log('scripts:', scripts.slice(0, 5).join('\n  '));
    console.log('has root div:', html.includes('id="root"'));
  }
})();
