import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { UsersRepository } from '../users/users.repository';

import { PaymobCardPayDto } from './dto/paymob-card-pay.dto';
import { PaymobCheckoutSessionStore } from './paymob-checkout.sessions';
import { buildPaymobSpecialReference } from './paymob-hmac.util';
import {
  renderPaymobHostedCheckoutPage,
  renderPaymobHostedCheckoutScript,
} from './paymob-hosted-checkout';

export type PaymobPlan = 'monthly' | 'yearly';

export interface PaymobCheckoutResult {
  checkoutUrl: string;
  clientSecret: string;
  publicKey: string;
  canUseNativeSdk: boolean;
  specialReference: string;
  amountCents: number;
  currency: string;
}

interface PaymobBillingData {
  apartment: string;
  first_name: string;
  last_name: string;
  street: string;
  building: string;
  phone_number: string;
  country: string;
  email: string;
  floor: string;
  state: string;
  city: string;
}

@Injectable()
export class PaymobService {
  private readonly logger = new Logger(PaymobService.name);
  private readonly baseUrl = 'https://accept.paymob.com';
  private readonly checkoutSessions = new PaymobCheckoutSessionStore();

  constructor(
    private readonly config: ConfigService,
    private readonly usersRepo: UsersRepository,
  ) {}

  private get apiKey(): string {
    return (this.config.get<string>('paymob.apiKey') ?? '').trim();
  }

  private get secretKey(): string {
    return (this.config.get<string>('paymob.secretKey') ?? '').trim();
  }

  private get publicKey(): string {
    return (this.config.get<string>('paymob.publicKey') ?? '').trim();
  }

  private get hmacSecret(): string {
    return (this.config.get<string>('paymob.hmacSecret') ?? '').trim();
  }

  private get integrationId(): number {
    return this.config.get<number>('paymob.integrationId') ?? 0;
  }

  private get iframeId(): number {
    return this.config.get<number>('paymob.iframeId') ?? 0;
  }

  get webhookUrl(): string {
    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    return `${base}/v1/subscription/paymob/webhook`;
  }

  get redirectUrl(): string {
    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    return `${base}/v1/subscription/paymob/redirect`;
  }

  private callbacksReachable(): boolean {
    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    return (
      !!base &&
      !base.includes('YOUR_PUBLIC_HOST') &&
      !base.includes('localhost') &&
      !base.includes('127.0.0.1')
    );
  }

  async createPremiumCheckout(
    userId: string,
    plan: PaymobPlan,
    checkoutBaseUrl?: string,
    requestOrigin?: string,
  ): Promise<PaymobCheckoutResult> {
    this.assertConfigured();
    this.warnIfCallbacksUnreachable();

    const user = await this.usersRepo.findActiveById(userId);
    if (!user) {
      throw new BadRequestException({ message: 'User not found.' });
    }

    const amountCents =
      plan === 'yearly'
        ? this.config.get<number>('paymob.yearlyAmountCents')!
        : this.config.get<number>('paymob.monthlyAmountCents')!;
    const currency = this.config.get<string>('paymob.currency') ?? 'EGP';
    const specialReference = buildPaymobSpecialReference(userId);
    const billingData = this.buildBillingData(user.name, user.email);

    const intention = await this.tryCreateIntention({
      amountCents,
      currency,
      plan,
      userId,
      specialReference,
      billingData,
    });
    if (intention) {
      return intention;
    }

    this.logger.warn(
      `Paymob intention API unavailable for integration ${this.integrationId}; ` +
        'using legacy payment key flow (typical for VPC/wallet integrations).',
    );

    const legacy = await this.createLegacyCheckout({
      amountCents,
      currency,
      plan,
      userId,
      specialReference,
      billingData,
    });

    return this.wrapLegacyCheckoutForHostedPage(legacy, {
      userId,
      plan,
      checkoutBaseUrl: this.resolveCheckoutBaseUrl(checkoutBaseUrl, requestOrigin),
    });
  }

  renderHostedCheckoutPage(sessionId: string): string {
    const session = this.checkoutSessions.get(sessionId);
    if (!session) {
      throw new BadRequestException({ message: 'Checkout session expired or not found.' });
    }

    const amountLabel = (session.amountCents / 100).toFixed(2);
    const planLabel =
      session.plan === 'yearly' ? 'Focusly Premium — Yearly' : 'Focusly Premium — Monthly';
    const checkoutBase = session.checkoutBaseUrl.replace(/\/$/, '');

    return renderPaymobHostedCheckoutPage({
      sessionId,
      amountLabel,
      currency: session.currency,
      planLabel,
      payUrl: `${checkoutBase}/v1/subscription/paymob/open/${sessionId}/pay`,
      scriptUrl: `${checkoutBase}/v1/subscription/paymob/open/${sessionId}/checkout.js`,
      appSuccessUrl:
        this.config.get<string>('paymob.appRedirectSuccess') ?? 'focusly://payment/success',
      appFailureUrl:
        this.config.get<string>('paymob.appRedirectFailure') ?? 'focusly://payment/failure',
    });
  }

  renderHostedCheckoutScript(sessionId: string): string {
    const session = this.checkoutSessions.get(sessionId);
    if (!session) {
      throw new BadRequestException({ message: 'Checkout session expired or not found.' });
    }

    const checkoutBase = session.checkoutBaseUrl.replace(/\/$/, '');
    return renderPaymobHostedCheckoutScript({
      payUrl: `${checkoutBase}/v1/subscription/paymob/open/${sessionId}/pay`,
      appSuccessUrl:
        this.config.get<string>('paymob.appRedirectSuccess') ?? 'focusly://payment/success',
      appFailureUrl:
        this.config.get<string>('paymob.appRedirectFailure') ?? 'focusly://payment/failure',
    });
  }

  async processHostedCardPayment(
    sessionId: string,
    card: PaymobCardPayDto,
  ): Promise<{
    success: boolean;
    message: string;
    redirectUrl?: string;
    terminalFailure?: boolean;
  }> {
    const session = this.checkoutSessions.get(sessionId);
    if (!session) {
      throw new BadRequestException({ message: 'Checkout session expired or not found.' });
    }

    const response = await fetch(`${this.baseUrl}/api/acceptance/payments/pay`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        source: {
          identifier: card.number,
          sourceholder_name: card.name,
          subtype: 'CARD',
          expiry_month: card.expiryMonth,
          expiry_year: card.expiryYear,
          cvn: card.cvv,
        },
        payment_token: session.paymentToken,
        api_source: 'IFRAME',
      }),
    });

    const data = (await response.json()) as Record<string, unknown>;
    const redirectUrl =
      typeof data.redirection_url === 'string'
        ? data.redirection_url
        : typeof data.redirect === 'string'
          ? data.redirect
          : undefined;

    if (response.ok && redirectUrl) {
      try {
        const redirectSuccess = new URL(redirectUrl).searchParams.get('success') === 'true';
        if (redirectSuccess) {
          return { success: false, message: 'Redirecting to complete payment…', redirectUrl };
        }
      } catch {
        return { success: false, message: 'Redirecting to complete payment…', redirectUrl };
      }

      return {
        success: false,
        message:
          `Paymob declined this card. Integration ${this.integrationId} is VPC/wallet — Visa test cards need ` +
          'an Online Card (MIGS) integration in Paymob Dashboard. Create one and set PAYMOB_INTEGRATION_ID.',
        terminalFailure: true,
      };
    }

    const success = data.success === true || data.success === 'true';
    if (response.ok && success) {
      this.checkoutSessions.delete(sessionId);
      return {
        success: true,
        message: 'Payment successful. Return to the Focusly app and tap Refresh.',
      };
    }

    const message =
      typeof data['data.message'] === 'string'
        ? data['data.message']
        : typeof data.message === 'string'
          ? data.message
          : 'Payment was declined. Check your card details or try another card.';

    return { success: false, message, terminalFailure: true };
  }

  private wrapLegacyCheckoutForHostedPage(
    legacy: PaymobCheckoutResult,
    input: { userId: string; plan: PaymobPlan; checkoutBaseUrl: string },
  ): PaymobCheckoutResult {
    if (this.isIntentionClientSecret(legacy.clientSecret)) {
      return legacy;
    }

    if (this.iframeId) {
      return legacy;
    }

    const base = input.checkoutBaseUrl;
    const session = this.checkoutSessions.create({
      userId: input.userId,
      plan: input.plan,
      paymentToken: legacy.clientSecret,
      amountCents: legacy.amountCents,
      currency: legacy.currency,
      specialReference: legacy.specialReference,
      checkoutBaseUrl: base,
    });
    return {
      ...legacy,
      checkoutUrl: `${base}/v1/subscription/paymob/open/${session.id}`,
    };
  }

  private isUsableCheckoutBaseUrl(url: string): boolean {
    if (!url || !/^https?:\/\//i.test(url)) {
      return false;
    }

    const lower = url.toLowerCase();
    if (lower.includes('your_public_host') || lower.includes('example.com')) {
      return false;
    }

    return true;
  }

  private resolveCheckoutBaseUrl(explicit?: string, requestOrigin?: string): string {
    const candidates = [
      explicit,
      requestOrigin,
      this.config.get<string>('paymob.checkoutBaseUrl'),
      this.config.get<string>('paymob.publicApiBaseUrl'),
    ];

    for (const raw of candidates) {
      const candidate = (raw ?? '').trim().replace(/\/$/, '');
      if (this.isUsableCheckoutBaseUrl(candidate) && !this.isLoopbackUrl(candidate)) {
        return candidate;
      }
    }

    for (const raw of candidates) {
      const candidate = (raw ?? '').trim().replace(/\/$/, '');
      if (this.isUsableCheckoutBaseUrl(candidate)) {
        return candidate;
      }
    }

    return `http://127.0.0.1:${process.env.PORT ?? '5000'}`;
  }

  private isLoopbackUrl(url: string): boolean {
    try {
      const { hostname } = new URL(url);
      return hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1';
    } catch {
      return true;
    }
  }

  buildCheckoutUrl(clientSecret: string): string {
    if (this.isIntentionClientSecret(clientSecret)) {
      return this.buildUnifiedCheckoutUrl(clientSecret);
    }

    return this.buildLegacyCheckoutUrl(clientSecret);
  }

  private isIntentionClientSecret(value: string): boolean {
    return /^egy_csk_/i.test(value) || /^csk_/i.test(value);
  }

  private buildUnifiedCheckoutUrl(clientSecret: string): string {
    const publicKey = encodeURIComponent(this.publicKey);
    const secret = encodeURIComponent(clientSecret);
    return `${this.baseUrl}/unifiedcheckout/?publicKey=${publicKey}&clientSecret=${secret}`;
  }

  private buildLegacyCheckoutUrl(paymentToken: string): string {
    const token = encodeURIComponent(paymentToken);

    if (this.iframeId) {
      return `${this.baseUrl}/api/acceptance/iframes/${this.iframeId}?payment_token=${token}`;
    }

    // VPC / legacy integrations without an iFrame entry (common in test accounts).
    return `${this.baseUrl}/standalone/?payment_token=${token}`;
  }

  private buildBillingData(name: string, email: string): PaymobBillingData {
    const parts = (name || 'Focusly User').trim().split(/\s+/);
    const firstName = parts[0] ?? 'Focusly';
    const lastName = parts.slice(1).join(' ') || 'User';

    return {
      apartment: 'NA',
      first_name: firstName,
      last_name: lastName,
      street: 'NA',
      building: 'NA',
      phone_number: '+201000000000',
      country: 'EG',
      email,
      floor: 'NA',
      state: 'NA',
      city: 'Cairo',
    };
  }

  private async tryCreateIntention(input: {
    amountCents: number;
    currency: string;
    plan: PaymobPlan;
    userId: string;
    specialReference: string;
    billingData: PaymobBillingData;
  }): Promise<PaymobCheckoutResult | null> {
    const body: Record<string, unknown> = {
      amount: input.amountCents,
      currency: input.currency,
      payment_methods: [this.integrationId],
      items: [
        {
          name: input.plan === 'yearly' ? 'Focusly Premium Yearly' : 'Focusly Premium Monthly',
          amount: input.amountCents,
          description: 'Focusly study app premium subscription',
          quantity: 1,
        },
      ],
      billing_data: input.billingData,
      special_reference: input.specialReference,
      extras: { plan: input.plan, userId: input.userId },
    };

    if (this.callbacksReachable()) {
      body.notification_url = this.webhookUrl;
      body.redirection_url = this.redirectUrl;
    }

    const response = await fetch(`${this.baseUrl}/v1/intention/`, {
      method: 'POST',
      headers: {
        Authorization: `Token ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = (await response.json()) as Record<string, unknown>;
    if (!response.ok) {
      const detail = typeof data.detail === 'string' ? data.detail : '';
      if (response.status === 404 && detail.includes('Integration')) {
        return null;
      }

      this.logger.error(`Paymob intention failed (${response.status}): ${JSON.stringify(data)}`);
      throw this.mapIntentionError(response.status, data);
    }

    const rawSecret = data.client_secret;
    const clientSecret =
      typeof rawSecret === 'string' || typeof rawSecret === 'number' ? String(rawSecret) : '';
    if (!clientSecret) {
      throw new ServiceUnavailableException({
        message: 'Paymob did not return a client secret.',
      });
    }

    return {
      checkoutUrl: this.buildCheckoutUrl(clientSecret),
      clientSecret,
      publicKey: this.publicKey,
      canUseNativeSdk: this.isIntentionClientSecret(clientSecret),
      specialReference: input.specialReference,
      amountCents: input.amountCents,
      currency: input.currency,
    };
  }

  private async createLegacyCheckout(input: {
    amountCents: number;
    currency: string;
    plan: PaymobPlan;
    userId: string;
    specialReference: string;
    billingData: PaymobBillingData;
  }): Promise<PaymobCheckoutResult> {
    const authToken = await this.fetchLegacyAuthToken();

    const orderResponse = await fetch(`${this.baseUrl}/api/ecommerce/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: authToken,
        delivery_needed: false,
        amount_cents: input.amountCents,
        currency: input.currency,
        merchant_order_id: input.specialReference,
        items: [
          {
            name: input.plan === 'yearly' ? 'Focusly Premium Yearly' : 'Focusly Premium Monthly',
            amount_cents: input.amountCents,
            description: 'Focusly study app premium subscription',
            quantity: 1,
          },
        ],
      }),
    });

    const orderData = (await orderResponse.json()) as Record<string, unknown>;
    if (!orderResponse.ok || orderData.id == null) {
      this.logger.error(`Paymob legacy order failed: ${JSON.stringify(orderData)}`);
      throw new BadRequestException({
        message: 'Could not create Paymob order.',
        details: orderData,
      });
    }

    const paymentKeyResponse = await fetch(`${this.baseUrl}/api/acceptance/payment_keys`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: authToken,
        amount_cents: input.amountCents,
        expiration: 3600,
        order_id: orderData.id,
        billing_data: input.billingData,
        currency: input.currency,
        integration_id: this.integrationId,
        extras: { plan: input.plan, userId: input.userId },
      }),
    });

    const paymentKeyData = (await paymentKeyResponse.json()) as Record<string, unknown>;
    const paymentToken =
      typeof paymentKeyData.token === 'string' ? paymentKeyData.token.trim() : '';

    if (!paymentKeyResponse.ok || !paymentToken) {
      this.logger.error(`Paymob legacy payment key failed: ${JSON.stringify(paymentKeyData)}`);
      throw new BadRequestException({
        message: 'Could not start Paymob checkout.',
        details: paymentKeyData,
      });
    }

    return {
      checkoutUrl: this.buildCheckoutUrl(paymentToken),
      clientSecret: paymentToken,
      publicKey: this.publicKey,
      canUseNativeSdk: false,
      specialReference: input.specialReference,
      amountCents: input.amountCents,
      currency: input.currency,
    };
  }

  private async fetchLegacyAuthToken(): Promise<string> {
    const response = await fetch(`${this.baseUrl}/api/auth/tokens`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: this.apiKey }),
    });

    const data = (await response.json()) as Record<string, unknown>;
    const token = typeof data.token === 'string' ? data.token.trim() : '';

    if (!response.ok || !token) {
      this.logger.error(`Paymob auth token failed: ${JSON.stringify(data)}`);
      throw new BadRequestException({
        message:
          'Paymob rejected the API key. Copy PAYMOB_API_KEY from Accept Dashboard → Settings (Test mode).',
        details: data,
      });
    }

    return token;
  }

  private assertConfigured(): void {
    if (
      !this.apiKey ||
      !this.secretKey ||
      !this.publicKey ||
      !this.integrationId ||
      !this.hmacSecret
    ) {
      throw new ServiceUnavailableException({
        message:
          'Paymob is not configured. Set PAYMOB_API_KEY, PAYMOB_SECRET_KEY, PAYMOB_PUBLIC_KEY, PAYMOB_INTEGRATION_ID, and PAYMOB_HMAC_SECRET.',
      });
    }
  }

  private warnIfCallbacksUnreachable(): void {
    if (this.callbacksReachable()) {
      return;
    }

    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    this.logger.warn(
      `PUBLIC_API_BASE_URL is "${base || '(empty)'}" — Paymob cannot reach the ` +
        'webhook/redirect callbacks, so premium will NOT be granted after payment. ' +
        'Run scripts/paymob-tunnel.ps1 (dev) or set a public HTTPS host, then ' +
        'update Integration Callbacks in Paymob dashboard (not the default post_pay URLs).',
    );
  }

  private mapIntentionError(status: number, data: Record<string, unknown>): BadRequestException {
    const detail = typeof data.detail === 'string' ? data.detail : undefined;

    if (
      status === 401 ||
      detail === 'Authentication credentials were not provided.' ||
      detail === 'Invalid token.'
    ) {
      return new BadRequestException({
        message:
          'Paymob rejected the secret key. In the Accept Dashboard (Test mode), copy a fresh Secret Key into PAYMOB_SECRET_KEY and ensure it matches your Integration ID mode.',
        details: data,
      });
    }

    return new BadRequestException({
      message: 'Could not start Paymob checkout.',
      details: data,
    });
  }
}
