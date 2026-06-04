require('dotenv').config();

const CARD = {
  name: 'Test Account',
  number: '4111111111111111',
  expiryMonth: '01',
  expiryYear: '39',
  cvv: '123',
};

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
      merchant_order_id: 'visa-test-' + Date.now(),
      items: [{ name: 'Premium', amount_cents: 9900, quantity: 1, description: 'test' }],
    }),
  }).then((r) => r.json());

  const pk = await fetch('https://accept.paymob.com/api/acceptance/payment_keys', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      auth_token: authToken,
      amount_cents: 9900,
      expiration: 3600,
      order_id: order.id,
      billing_data: {
        first_name: 'Test',
        last_name: 'Account',
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
      integration_id: Number(process.env.PAYMOB_INTEGRATION_ID),
    }),
  }).then((r) => r.json());

  const pay = await fetch('https://accept.paymob.com/api/acceptance/payments/pay', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      source: {
        identifier: CARD.number,
        sourceholder_name: CARD.name,
        subtype: 'CARD',
        expiry_month: CARD.expiryMonth,
        expiry_year: CARD.expiryYear,
        cvn: CARD.cvv,
      },
      payment_token: pk.token,
      api_source: 'IFRAME',
    }),
  });

  const data = await pay.json();
  console.log('integration', process.env.PAYMOB_INTEGRATION_ID);
  console.log('success', data.success);
  console.log('error_occured', data.error_occured);
  console.log('data.message', data['data.message']);
  console.log('txn_response_code', data.txn_response_code);
  console.log('acq_response_code', data.acq_response_code);
  if (data.redirection_url) {
    const u = new URL(data.redirection_url);
    console.log('redirect success=', u.searchParams.get('success'));
  }
})();
