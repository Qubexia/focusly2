// Fully automated card charge via Paymob's direct API (no browser).
// auth -> order -> payment_key -> pay. merchant_order_id embeds the real userId
// so the webhook (if dashboard callback points at the tunnel) activates premium.
// Run: node scripts/auto-pay-test.cjs
require('dotenv').config();

const USER_ID = '6a1b6186d06b43f6268c6ec4'; // zezosaad194@gmail.com
const AMOUNT = 9900;

// A few Paymob sandbox test cards to try in order.
const CARDS = [
  { label: 'MC 5123…2346', number: '5123456789012346', expiryMonth: '12', expiryYear: '30', cvv: '123' },
  { label: 'VISA 4987…0008', number: '4987654321000008', expiryMonth: '12', expiryYear: '30', cvv: '123' },
  { label: 'VISA 4111…1111', number: '4111111111111111', expiryMonth: '01', expiryYear: '39', cvv: '123' },
];

async function j(url, body) {
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: r.status, data: await r.json() };
}

async function attempt(authToken, integrationId, card, uuid) {
  const merchantOrderId = `focusly-user-${USER_ID}-${uuid}`;
  const order = await j('https://accept.paymob.com/api/ecommerce/orders', {
    auth_token: authToken,
    delivery_needed: false,
    amount_cents: AMOUNT,
    currency: 'EGP',
    merchant_order_id: merchantOrderId,
    items: [{ name: 'Focusly Premium Monthly', amount_cents: AMOUNT, quantity: 1, description: 'premium' }],
  });
  if (!order.data.id) {
    return { ok: false, stage: 'order', detail: order.data };
  }

  const pk = await j('https://accept.paymob.com/api/acceptance/payment_keys', {
    auth_token: authToken,
    amount_cents: AMOUNT,
    expiration: 3600,
    order_id: order.data.id,
    billing_data: {
      first_name: 'zezo', last_name: 'User', phone_number: '+201000000000',
      email: 'zezosaad194@gmail.com', country: 'EG', city: 'Cairo',
      street: 'NA', building: 'NA', floor: 'NA', apartment: 'NA',
    },
    currency: 'EGP',
    integration_id: Number(integrationId),
  });
  if (!pk.data.token) {
    return { ok: false, stage: 'payment_key', detail: pk.data };
  }

  const pay = await j('https://accept.paymob.com/api/acceptance/payments/pay', {
    source: {
      identifier: card.number,
      sourceholder_name: card.label,
      subtype: 'CARD',
      expiry_month: card.expiryMonth,
      expiry_year: card.expiryYear,
      cvn: card.cvv,
    },
    payment_token: pk.data.token,
    api_source: 'IFRAME',
  });

  return {
    ok: true,
    stage: 'pay',
    httpStatus: pay.status,
    merchantOrderId,
    orderId: order.data.id,
    success: pay.data.success,
    pending: pay.data.pending,
    error_occured: pay.data.error_occured,
    message: pay.data['data.message'] ?? pay.data.message,
    txn_response_code: pay.data.txn_response_code,
    transactionId: pay.data.id,
    redirection_url: pay.data.redirection_url,
    iframe_redirection_url: pay.data.iframe_redirection_url,
  };
}

(async () => {
  const apiKey = process.env.PAYMOB_API_KEY.trim();
  const integrationId = process.env.PAYMOB_INTEGRATION_ID;
  const auth = await j('https://accept.paymob.com/api/auth/tokens', { api_key: apiKey });
  if (!auth.data.token) {
    console.error('AUTH FAILED:', JSON.stringify(auth.data).slice(0, 400));
    process.exit(1);
  }
  console.log('auth ok | integration', integrationId);

  // Deterministic-ish uuid per run without Math.random/Date in a workflow ctx (plain node here is fine).
  const { randomUUID } = require('crypto');

  for (const card of CARDS) {
    const res = await attempt(auth.data.token, integrationId, card, randomUUID());
    console.log('\n=== card', card.label, '===');
    console.log(JSON.stringify(res, null, 2));
    if (res.ok && (res.success === true || res.pending === true || res.redirection_url || res.iframe_redirection_url)) {
      console.log('\n>>> Stopping — this card produced a charge/3DS step. <<<');
      break;
    }
  }
})().catch((e) => { console.error('ERROR', e); process.exit(1); });
