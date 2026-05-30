import { createHmac } from 'crypto';

/** Paymob "Transaction Processed" callback HMAC (Accept API). */
export function computeTransactionProcessedHmac(
  transaction: Record<string, unknown>,
  hmacSecret: string,
): string {
  const order = transaction.order as Record<string, unknown> | undefined;
  const sourceData = transaction.source_data as Record<string, unknown> | undefined;

  const parts = [
    transaction.amount_cents,
    transaction.created_at,
    transaction.currency,
    transaction.error_occured,
    transaction.has_parent_transaction,
    transaction.id,
    transaction.integration_id,
    transaction.is_3d_secure,
    transaction.is_auth,
    transaction.is_capture,
    transaction.is_refunded,
    transaction.is_standalone_payment,
    transaction.is_voided,
    order?.id,
    transaction.owner,
    transaction.pending,
    sourceData?.pan,
    sourceData?.sub_type,
    sourceData?.type,
    transaction.success,
  ];

  const concatenated = parts.map((v) => String(v ?? '')).join('');
  return createHmac('sha512', hmacSecret).update(concatenated).digest('hex');
}

export function verifyTransactionProcessedHmac(
  transaction: Record<string, unknown>,
  receivedHmac: string,
  hmacSecret: string,
): boolean {
  if (!receivedHmac || !hmacSecret) return false;
  const expected = computeTransactionProcessedHmac(transaction, hmacSecret);
  return expected.toLowerCase() === receivedHmac.toLowerCase();
}

/** Extract user id from `focusly-user-{mongoId}` special_reference. */
export function parseUserIdFromSpecialReference(reference: string | undefined): string | null {
  if (!reference?.startsWith('focusly-user-')) return null;
  return reference.slice('focusly-user-'.length) || null;
}
