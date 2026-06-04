import { randomUUID } from 'crypto';

import { PaymobPlan } from './paymob.service';

export interface PaymobCheckoutSession {
  id: string;
  userId: string;
  plan: PaymobPlan;
  paymentToken: string;
  amountCents: number;
  currency: string;
  specialReference: string;
  checkoutBaseUrl: string;
  expiresAt: number;
}

const TTL_MS = 60 * 60 * 1000;

export class PaymobCheckoutSessionStore {
  private readonly sessions = new Map<string, PaymobCheckoutSession>();

  create(input: Omit<PaymobCheckoutSession, 'id' | 'expiresAt'>): PaymobCheckoutSession {
    this.pruneExpired();

    const session: PaymobCheckoutSession = {
      ...input,
      id: randomUUID(),
      expiresAt: Date.now() + TTL_MS,
    };

    this.sessions.set(session.id, session);
    return session;
  }

  get(sessionId: string): PaymobCheckoutSession | null {
    this.pruneExpired();
    const session = this.sessions.get(sessionId);
    if (!session) {
      return null;
    }

    if (session.expiresAt <= Date.now()) {
      this.sessions.delete(sessionId);
      return null;
    }

    return session;
  }

  delete(sessionId: string): void {
    this.sessions.delete(sessionId);
  }

  private pruneExpired(): void {
    const now = Date.now();
    for (const [id, session] of this.sessions.entries()) {
      if (session.expiresAt <= now) {
        this.sessions.delete(id);
      }
    }
  }
}
