require('dotenv').config();

(async () => {
  const apiKey = process.env.PAYMOB_API_KEY.trim();
  const { token } = await fetch('https://accept.paymob.com/api/auth/tokens', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ api_key: apiKey }),
  }).then((r) => r.json());

  const paths = [
    'ecommerce/settings',
    'acceptance/settings',
    'ecommerce/profile',
    'acceptance/profile',
    'ecommerce/merchants/profile',
  ];

  for (const p of paths) {
    const r = await fetch(`https://accept.paymob.com/api/${p}`, {
      headers: { Authorization: 'Bearer ' + token },
    });
    console.log('\n', p, r.status, (await r.text()).slice(0, 500));
  }
})();
