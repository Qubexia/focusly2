import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';

@Injectable()
export class StripeService {
  private readonly stripe: Stripe;

  constructor(private readonly config: ConfigService) {
    const key = this.config.get<string>('stripe.secretKey');
    this.stripe = key ? new Stripe(key, { apiVersion: '2025-02-24' as any }) : (null as any);
  }

  createCheckoutSession(userId: string): Promise<Stripe.Checkout.Session> {
    return this.stripe.checkout.sessions.create({
      mode: 'subscription',
      metadata: { userId },
      line_items: [{ price: this.config.get<string>('stripe.priceId')!, quantity: 1 }],
      success_url: this.config.get<string>('stripe.successUrl')!,
      cancel_url: this.config.get<string>('stripe.cancelUrl')!,
    });
  }

  createPortalSession(customerId: string): Promise<Stripe.BillingPortal.Session> {
    return this.stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: this.config.get<string>('stripe.portalReturnUrl')!,
    });
  }

  constructWebhookEvent(payload: Buffer, signature: string): Stripe.Event {
    const secret = this.config.get<string>('stripe.webhookSecret')!;
    return this.stripe.webhooks.constructEvent(payload, signature, secret);
  }
}
