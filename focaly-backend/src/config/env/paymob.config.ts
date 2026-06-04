import { registerAs } from '@nestjs/config';

export default registerAs('paymob', () => ({
  apiKey: process.env.PAYMOB_API_KEY ?? '',
  publicKey: process.env.PAYMOB_PUBLIC_KEY ?? '',
  secretKey: process.env.PAYMOB_SECRET_KEY ?? '',
  hmacSecret: process.env.PAYMOB_HMAC_SECRET ?? '',
  integrationId: Number(process.env.PAYMOB_INTEGRATION_ID ?? 0),
  iframeId: Number(process.env.PAYMOB_IFRAME_ID ?? 0),
  currency: process.env.PAYMOB_CURRENCY ?? 'EGP',
  monthlyAmountCents: Number(process.env.PAYMOB_PREMIUM_MONTHLY_AMOUNT_CENTS ?? 9900),
  yearlyAmountCents: Number(process.env.PAYMOB_PREMIUM_YEARLY_AMOUNT_CENTS ?? 99900),
  publicApiBaseUrl: (process.env.PUBLIC_API_BASE_URL ?? 'http://localhost:3000').replace(
    /\/$/,
    '',
  ),
  checkoutBaseUrl: (process.env.PAYMOB_CHECKOUT_BASE_URL ?? '').replace(/\/$/, ''),
  appRedirectSuccess: process.env.PAYMOB_APP_SUCCESS_URL ?? 'focusly://payment/success',
  appRedirectFailure: process.env.PAYMOB_APP_FAILURE_URL ?? 'focusly://payment/failure',
}));
