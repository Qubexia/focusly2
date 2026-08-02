import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';

/**
 * Keys rate-limit buckets on the client IP as resolved by Express.
 *
 * `app.set('trust proxy', 1)` in main.ts makes `req.ip` the last hop the
 * trusted proxy saw, so a client cannot mint a fresh bucket per request by
 * sending its own X-Forwarded-For — which reading the raw header would allow.
 */
@Injectable()
export class ThrottlerBehindProxyGuard extends ThrottlerGuard {
  protected getTracker(req: Record<string, unknown>): Promise<string> {
    const ip = req.ip;
    if (typeof ip === 'string' && ip.length > 0) {
      return Promise.resolve(ip);
    }

    const socket = req.socket as { remoteAddress?: string } | undefined;
    return Promise.resolve(socket?.remoteAddress ?? 'unknown');
  }
}
