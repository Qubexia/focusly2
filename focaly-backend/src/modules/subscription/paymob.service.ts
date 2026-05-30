import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { UsersRepository } from '../users/users.repository';

export type PaymobPlan = 'monthly' | 'yearly';

export interface PaymobCheckoutResult {
  checkoutUrl: string;
  clientSecret: string;
  specialReference: string;
  amountCents: number;
  currency: string;
}

@Injectable()
export class PaymobService {
  private readonly logger = new Logger(PaymobService.name);
  private readonly baseUrl = 'https://accept.paymob.com';

  constructor(
    private readonly config: ConfigService,
    private readonly usersRepo: UsersRepository,
  ) {}

  private get secretKey(): string {
    return this.config.get<string>('paymob.secretKey') ?? '';
  }

  private get publicKey(): string {
    return this.config.get<string>('paymob.publicKey') ?? '';
  }

  private get hmacSecret(): string {
    return this.config.get<string>('paymob.hmacSecret') ?? '';
  }

  private get integrationId(): number {
    return this.config.get<number>('paymob.integrationId') ?? 0;
  }

  get webhookUrl(): string {
    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    return `${base}/v1/subscription/paymob/webhook`;
  }

  get redirectUrl(): string {
    const base = this.config.get<string>('paymob.publicApiBaseUrl') ?? '';
    return `${base}/v1/subscription/paymob/redirect`;
  }

  async createPremiumCheckout(userId: string, plan: PaymobPlan): Promise<PaymobCheckoutResult> {
    this.assertConfigured();

    const user = await this.usersRepo.findActiveById(userId);
    if (!user) {
      throw new BadRequestException({ message: 'User not found.' });
    }

    const amountCents =
      plan === 'yearly'
        ? this.config.get<number>('paymob.yearlyAmountCents')!
        : this.config.get<number>('paymob.monthlyAmountCents')!;
    const currency = this.config.get<string>('paymob.currency') ?? 'EGP';
    const specialReference = `focusly-user-${userId}`;

    const [firstName, ...rest] = (user.name || 'Focusly User').trim().split(/\s+/);
    const lastName = rest.join(' ') || 'User';

    const body = {
      amount: amountCents,
      currency,
      payment_methods: [this.integrationId],
      items: [
        {
          name: plan === 'yearly' ? 'Focusly Premium Yearly' : 'Focusly Premium Monthly',
          amount: amountCents,
          description: 'Focusly study app premium subscription',
          quantity: 1,
        },
      ],
      billing_data: {
        apartment: 'NA',
        first_name: firstName,
        last_name: lastName,
        street: 'NA',
        building: 'NA',
        phone_number: '+201000000000',
        country: 'EG',
        email: user.email,
        floor: 'NA',
        state: 'NA',
        city: 'Cairo',
      },
      special_reference: specialReference,
      notification_url: this.webhookUrl,
      redirection_url: this.redirectUrl,
      extras: { plan, userId },
    };

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
      this.logger.error(`Paymob intention failed: ${JSON.stringify(data)}`);
      throw new BadRequestException({
        message: 'Could not start Paymob checkout.',
        details: data,
      });
    }

    const clientSecret = String(data.client_secret ?? '');
    if (!clientSecret) {
      throw new ServiceUnavailableException({
        message: 'Paymob did not return a client secret.',
      });
    }

    const checkoutUrl = this.buildCheckoutUrl(clientSecret);

    return {
      checkoutUrl,
      clientSecret,
      specialReference,
      amountCents,
      currency,
    };
  }

  buildCheckoutUrl(clientSecret: string): string {
    const publicKey = encodeURIComponent(this.publicKey);
    const secret = encodeURIComponent(clientSecret);
    return `${this.baseUrl}/unifiedcheckout/?publicKey=${publicKey}&clientSecret=${secret}`;
  }

  private assertConfigured(): void {
    if (!this.secretKey || !this.publicKey || !this.integrationId || !this.hmacSecret) {
      throw new ServiceUnavailableException({
        message:
          'Paymob is not configured. Set PAYMOB_SECRET_KEY, PAYMOB_PUBLIC_KEY, PAYMOB_INTEGRATION_ID, and PAYMOB_HMAC_SECRET.',
      });
    }
  }
}
