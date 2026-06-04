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
      merchant_order_id: 'pay-test-' + Date.now(),
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

  const body = {
    source: {
      identifier: '4987654321098769',
      sourceholder_name: 'Test User',
      subtype: 'CARD',
      expiry_month: '12',
      expiry_year: '25',
      cvn: '123',
    },
    payment_token: paymentToken,
    api_source: 'IFRAME',
  };

  const pay = await fetch('https://accept.paymob.com/api/acceptance/payments/pay', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify(body),
  });

  const data = await pay.json();
  console.log(JSON.stringify(data, null, 2).slice(0, 2500));
})();
