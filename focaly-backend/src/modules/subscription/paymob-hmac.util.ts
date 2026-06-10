import { createHmac, randomUUID } from 'crypto';

function hmacPart(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return '';
}

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

  const concatenated = parts.map((v) => hmacPart(v)).join('');
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

/**
 * Paymob "Transaction Response" (redirect) HMAC. It uses the SAME ordered
 * fields as the processed callback, but the redirect delivers them as FLAT
 * query params: `order` is the order id (not a nested object) and source_data
 * arrives under dotted keys (`source_data.pan`, etc.).
 */
export function computeResponseCallbackHmac(
  query: Record<string, unknown>,
  hmacSecret: string,
): string {
  const parts = [
    query.amount_cents,
    query.created_at,
    query.currency,
    query.error_occured,
    query.has_parent_transaction,
    query.id,
    query.integration_id,
    query.is_3d_secure,
    query.is_auth,
    query.is_capture,
    query.is_refunded,
    query.is_standalone_payment,
    query.is_voided,
    query.order,
    query.owner,
    query.pending,
    query['source_data.pan'],
    query['source_data.sub_type'],
    query['source_data.type'],
    query.success,
  ];

  const concatenated = parts.map((v) => hmacPart(v)).join('');
  return createHmac('sha512', hmacSecret).update(concatenated).digest('hex');
}

export function verifyResponseCallbackHmac(
  query: Record<string, unknown>,
  receivedHmac: string,
  hmacSecret: string,
): boolean {
  if (!receivedHmac || !hmacSecret) return false;
  const expected = computeResponseCallbackHmac(query, hmacSecret);
  return expected.toLowerCase() === receivedHmac.toLowerCase();
}

/** Build a unique Paymob order reference that still embeds the Mongo user id. */
export function buildPaymobSpecialReference(userId: string): string {
  return `zakerly-user-${userId}-${randomUUID()}`;
}

/** Extract user id from `zakerly-user-{mongoId}` or legacy `focusly-user-{mongoId}`. */
export function parseUserIdFromSpecialReference(reference: string | undefined): string | null {
  if (!reference) return null;
  const prefixes = ['zakerly-user-', 'focusly-user-'];
  const prefix = prefixes.find((p) => reference.startsWith(p));
  if (!prefix) return null;
  const rest = reference.slice(prefix.length);
  const match = rest.match(/^([a-f0-9]{24})(?:-|$)/i);
  return match?.[1] ?? null;
}
