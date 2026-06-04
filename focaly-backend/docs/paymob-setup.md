# Paymob setup (Focusly)

## Environment variables

Add to `focaly-backend/.env` (do not commit secrets):

```env
PAYMOB_API_KEY=
PAYMOB_PUBLIC_KEY=egy_pk_test_...
PAYMOB_SECRET_KEY=egy_sk_test_...
PAYMOB_HMAC_SECRET=
PAYMOB_INTEGRATION_ID=5690496
PAYMOB_IFRAME_ID=

# Required for VPC/wallet integrations (legacy iframe checkout).
# For card payments in the mobile app, prefer an Online Card (MIGS) integration ID instead.

PUBLIC_API_BASE_URL=https://YOUR_PUBLIC_HTTPS_HOST

PAYMOB_PREMIUM_MONTHLY_AMOUNT_CENTS=9900
PAYMOB_PREMIUM_YEARLY_AMOUNT_CENTS=99900
PAYMOB_CURRENCY=EGP

PAYMOB_APP_SUCCESS_URL=focusly://payment/success
PAYMOB_APP_FAILURE_URL=focusly://payment/failure
```

Paymob intention API expects:

```http
Authorization: Token <PAYMOB_SECRET_KEY>
```

(not `Bearer`). The backend uses this format in `paymob.service.ts`.

Test credentials locally:

```bash
npm run paymob:test
```

## Integration type (important)

| Type | Example | Checkout |
|------|---------|----------|
| **Online Card (MIGS)** | Card payments in app/browser | Intention API → Unified Checkout (`egy_csk_…`) |
| **VPC / wallet** | Integration `5690496` (Aman, Masary, …) | Legacy payment key → `/standalone/?payment_token=…` (or iFrame if `PAYMOB_IFRAME_ID` is set) |

If Unified Checkout shows **"Something went wrong"**, your integration is likely VPC-only. Either:

1. **Recommended:** Create **Online Card** under Developers → Payment Integrations (Test), set `PAYMOB_INTEGRATION_ID` to that ID.
2. **Already works for VPC:** the backend opens `https://accept.paymob.com/standalone/?payment_token=…` automatically (no iFrame required). Optionally set `PAYMOB_IFRAME_ID` to use the iFrame URL instead.


| Setting | URL |
|---------|-----|
| Transaction processed (webhook) | `{PUBLIC_API_BASE_URL}/v1/subscription/paymob/webhook` |
| Transaction response (redirect) | `{PUBLIC_API_BASE_URL}/v1/subscription/paymob/redirect` |

Verify at runtime: `GET {PUBLIC_API_BASE_URL}/v1/subscription/paymob/config-urls`

## Flutter app return URLs

After payment, Paymob redirects to the backend `/redirect` page, which links to:

- Success: `focusly://payment/success`
- Failure: `focusly://payment/failure`

The app opens Premium and refreshes subscription status.

## Test flow

1. Start backend with Paymob env vars set.
2. Run Flutter app, sign in, open **Premium**.
3. Tap **Pay with Paymob**, complete test payment in browser.
4. Tap **Return to Focusly app** (or deep link opens automatically).
5. Tap **Refresh** on Premium if plan is not updated yet (webhook may take a few seconds).
