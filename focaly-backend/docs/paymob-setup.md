# Paymob setup (Focusly)

## Environment variables

Add to `focaly-backend/.env` (do not commit secrets):

```env
PAYMOB_API_KEY=
PAYMOB_PUBLIC_KEY=egy_pk_test_...
PAYMOB_SECRET_KEY=egy_sk_test_...
PAYMOB_HMAC_SECRET=
PAYMOB_INTEGRATION_ID=5690496

PUBLIC_API_BASE_URL=https://YOUR_PUBLIC_HTTPS_HOST

PAYMOB_PREMIUM_MONTHLY_AMOUNT_CENTS=9900
PAYMOB_PREMIUM_YEARLY_AMOUNT_CENTS=99900
PAYMOB_CURRENCY=EGP

PAYMOB_APP_SUCCESS_URL=focusly://payment/success
PAYMOB_APP_FAILURE_URL=focusly://payment/failure
```

`PUBLIC_API_BASE_URL` must be reachable from the internet (use [ngrok](https://ngrok.com) for local dev: `ngrok http 3000`).

## Paymob dashboard URLs

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
