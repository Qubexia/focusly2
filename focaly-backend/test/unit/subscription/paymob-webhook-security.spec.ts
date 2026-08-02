import { UnauthorizedException } from '@nestjs/common';

import {
  computeTransactionProcessedHmac,
  verifyTransactionProcessedHmac,
} from '../../../src/modules/subscription/paymob-hmac.util';
import { PaymobController } from '../../../src/modules/subscription/paymob.controller';
import { PaymobService } from '../../../src/modules/subscription/paymob.service';
import { SubscriptionsService } from '../../../src/modules/subscription/subscriptions.service';

const HMAC_SECRET = 'test-hmac-secret';
const MONTHLY_CENTS = 15_000;
const YEARLY_CENTS = 120_000;

function paymobServiceStub(): PaymobService {
  return {
    callbackHmacSecret: HMAC_SECRET,
    currency: 'EGP',
    resolvePlanFromAmount: (amount: unknown) => {
      const paid = Number(amount);
      if (!Number.isFinite(paid)) return null;
      if (paid >= YEARLY_CENTS) return 'yearly';
      if (paid >= MONTHLY_CENTS) return 'monthly';
      return null;
    },
  } as unknown as PaymobService;
}

/** Minimal successful transaction for user `userId` paying `amountCents`. */
function transactionFor(userId: string, amountCents: number): Record<string, unknown> {
  return {
    amount_cents: amountCents,
    created_at: '2026-07-28T00:00:00Z',
    currency: 'EGP',
    error_occured: false,
    has_parent_transaction: false,
    id: 987654,
    integration_id: 111,
    is_3d_secure: true,
    is_auth: false,
    is_capture: false,
    is_refunded: false,
    is_standalone_payment: true,
    is_voided: false,
    order: { id: 42, merchant_order_id: `zakerly-user-${userId}-abc` },
    owner: 7,
    pending: false,
    source_data: { pan: '2346', sub_type: 'MasterCard', type: 'card' },
    success: true,
  };
}

describe('Paymob webhook security', () => {
  let applyEvent: jest.Mock;
  let controller: PaymobController;

  beforeEach(() => {
    applyEvent = jest.fn(() => Promise.resolve({ outcome: 'applied' }));
    controller = new PaymobController(paymobServiceStub(), {
      applyEvent,
    } as unknown as SubscriptionsService);
  });

  const requestFor = (transaction: Record<string, unknown>) =>
    ({ body: { obj: transaction }, headers: {} }) as never;

  it('rejects a forged callback that carries no HMAC at all', async () => {
    const forged = transactionFor('507f1f77bcf86cd799439011', YEARLY_CENTS);

    await expect(controller.handleWebhook(requestFor(forged))).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(applyEvent).not.toHaveBeenCalled();
  });

  it('rejects a callback whose HMAC does not match the payload', async () => {
    const tampered = transactionFor('507f1f77bcf86cd799439011', YEARLY_CENTS);
    const hmacForSomethingElse = computeTransactionProcessedHmac(
      transactionFor('507f1f77bcf86cd799439011', MONTHLY_CENTS),
      HMAC_SECRET,
    );

    await expect(
      controller.handleWebhook(requestFor(tampered), hmacForSomethingElse),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(applyEvent).not.toHaveBeenCalled();
  });

  it('grants only the plan the paid amount covers, ignoring extras.plan', async () => {
    const userId = '507f1f77bcf86cd799439011';
    // Paid for a month but claims a year in the client-controlled extras.
    const transaction = { ...transactionFor(userId, MONTHLY_CENTS), extras: { plan: 'yearly' } };
    const hmac = computeTransactionProcessedHmac(transaction, HMAC_SECRET);

    await controller.handleWebhook(requestFor(transaction), hmac);

    expect(applyEvent).toHaveBeenCalledTimes(1);
    const firstCall = applyEvent.mock.calls[0] as
      | [{ userId: string; currentPeriodEnd: Date }]
      | undefined;
    const applied = firstCall![0];
    expect(applied.userId).toBe(userId);

    const grantedDays = (applied.currentPeriodEnd.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
    expect(grantedDays).toBeLessThan(40);
  });

  it('ignores a successful payment that is below every plan price', async () => {
    const transaction = transactionFor('507f1f77bcf86cd799439011', 1);
    const hmac = computeTransactionProcessedHmac(transaction, HMAC_SECRET);

    const result = await controller.handleWebhook(requestFor(transaction), hmac);

    expect(result).toMatchObject({ outcome: 'ignored', reason: 'amount_mismatch' });
    expect(applyEvent).not.toHaveBeenCalled();
  });

  it('accepts a correctly signed, correctly priced payment', async () => {
    const userId = '507f1f77bcf86cd799439011';
    const transaction = transactionFor(userId, YEARLY_CENTS);
    const hmac = computeTransactionProcessedHmac(transaction, HMAC_SECRET);

    const result = await controller.handleWebhook(requestFor(transaction), hmac);

    expect(result).toMatchObject({ received: true, outcome: 'applied' });
    expect(applyEvent).toHaveBeenCalledTimes(1);
  });
});

describe('verifyTransactionProcessedHmac', () => {
  it('refuses to verify when the secret is missing', () => {
    const tx = transactionFor('507f1f77bcf86cd799439011', MONTHLY_CENTS);
    expect(verifyTransactionProcessedHmac(tx, 'anything', '')).toBe(false);
  });

  it('refuses an empty received signature', () => {
    const tx = transactionFor('507f1f77bcf86cd799439011', MONTHLY_CENTS);
    expect(verifyTransactionProcessedHmac(tx, '', HMAC_SECRET)).toBe(false);
  });

  it('accepts the signature it computes for the same payload', () => {
    const tx = transactionFor('507f1f77bcf86cd799439011', MONTHLY_CENTS);
    const hmac = computeTransactionProcessedHmac(tx, HMAC_SECRET);
    expect(verifyTransactionProcessedHmac(tx, hmac.toUpperCase(), HMAC_SECRET)).toBe(true);
  });
});
