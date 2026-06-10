// End-to-end Paymob checkout for a REAL user, mirroring exactly what the server
// builds (special_reference embeds the userId, callbacks point at the tunnel).
// Run: node scripts/probe-intention-quick.cjs
require('dotenv').config();

const crypto = require('crypto');

const SECRET_KEY = process.env.PAYMOB_SECRET_KEY?.trim();
const PUBLIC_KEY = process.env.PAYMOB_PUBLIC_KEY?.trim();
const INTEGRATION_ID = Number(process.env.PAYMOB_INTEGRATION_ID);
const BASE_URL = 'https://accept.paymob.com';

// Public tunnel that fronts the local backend (must stay running).
const PUBLIC_API_BASE = process.env.PAYMOB_PUBLIC_API_BASE?.trim();
const USER_ID = process.env.PAYMOB_PROBE_USER_ID?.trim();

async function main() {
  if (!SECRET_KEY || !PUBLIC_KEY || !INTEGRATION_ID || !PUBLIC_API_BASE || !USER_ID) {
    console.error(
      'Missing env: PAYMOB_SECRET_KEY, PAYMOB_PUBLIC_KEY, PAYMOB_INTEGRATION_ID, PAYMOB_PUBLIC_API_BASE, PAYMOB_PROBE_USER_ID',
    );
    process.exitCode = 1;
    return;
  }

  const specialReference = `Zakerly-user-${USER_ID}-${crypto.randomUUID()}`;
  const body = {
    amount: 9900,
    currency: 'EGP',
    payment_methods: [INTEGRATION_ID],
    items: [
      {
        name: 'Zakerly Premium Monthly',
        amount: 9900,
        description: 'Zakerly study app premium subscription',
        quantity: 1,
      },
    ],
    billing_data: {
      apartment: 'NA',
      first_name: 'zezo',
      last_name: 'User',
      street: 'NA',
      building: 'NA',
      phone_number: '+201000000000',
      country: 'EG',
      email: 'zezosaad194@gmail.com',
      floor: 'NA',
      state: 'NA',
      city: 'Cairo',
    },
    special_reference: specialReference,
    notification_url: `${PUBLIC_API_BASE}/v1/subscription/paymob/webhook`,
    redirection_url: `${PUBLIC_API_BASE}/v1/subscription/paymob/redirect`,
    extras: { plan: 'monthly', userId: USER_ID },
  };

  const res = await fetch(`${BASE_URL}/v1/intention/`, {
    method: 'POST',
    headers: { Authorization: `Token ${SECRET_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const data = await res.json();
  console.log('HTTP status:', res.status);
  if (!res.ok) {
    console.error('FAILED:', JSON.stringify(data, null, 2));
    process.exitCode = 1;
    return;
  }

  const clientSecret = data.client_secret;
  console.log('special_reference:', specialReference);
  console.log('client_secret    :', clientSecret);
  console.log('');
  console.log('>>> OPEN THIS URL IN A BROWSER AND PAY WITH THE TEST CARD <<<');
  console.log(`${BASE_URL}/unifiedcheckout/?publicKey=${PUBLIC_KEY}&clientSecret=${encodeURIComponent(clientSecret)}`);
}

main().catch((e) => {
  console.error('ERROR:', e);
  process.exitCode = 1;
});
