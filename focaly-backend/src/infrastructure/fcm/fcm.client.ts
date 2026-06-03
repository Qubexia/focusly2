import { readFileSync } from 'node:fs';

import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

import { FcmClient, FcmMessage, FcmSendResult } from './fcm.tokens';

@Injectable()
export class FcmRealClient implements FcmClient, OnModuleInit {
  private readonly logger = new Logger(FcmRealClient.name);
  private app: admin.app.App | null = null;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const inlineJson = this.config.get<string>('fcm.serviceAccountJson');
    const jsonPath = this.config.get<string>('fcm.serviceAccountPath');

    if (!inlineJson && !jsonPath) {
      this.logger.warn(
        'FCM credentials are missing. Set FCM_SERVICE_ACCOUNT_JSON or FCM_SERVICE_ACCOUNT_PATH.',
      );
      return;
    }

    let credentials: admin.ServiceAccount;
    try {
      const json = inlineJson || readFileSync(jsonPath!, 'utf8');
      credentials = JSON.parse(json) as admin.ServiceAccount;
    } catch (err: unknown) {
      const reason = err instanceof Error ? err.message : String(err);
      this.logger.warn(
        `FCM credentials could not be loaded; push notifications are disabled. ${reason}`,
      );
      return;
    }

    const existingApp = admin.apps.find(
      (app): app is admin.app.App => app != null && app.name === 'focaly',
    );
    if (existingApp) {
      this.app = existingApp;
      return;
    }

    this.app = admin.initializeApp({ credential: admin.credential.cert(credentials) }, 'focaly');
  }

  async send(messages: FcmMessage[]): Promise<FcmSendResult> {
    if (!this.app) {
      throw new Error(
        'FCM client not initialized; check FCM_SERVICE_ACCOUNT_JSON or FCM_SERVICE_ACCOUNT_PATH',
      );
    }

    const failureTokens: FcmSendResult['failureTokens'] = [];
    let successCount = 0;

    for (const msg of messages) {
      try {
        await admin.messaging(this.app).send({
          token: msg.token,
          notification: { title: msg.title, body: msg.body },
          data: msg.data,
        });
        successCount++;
      } catch (err: unknown) {
        const code = (err as { code?: string }).code ?? 'unknown';
        const permanent =
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token';
        failureTokens.push({ token: msg.token, permanent, reason: code });
      }
    }

    return { successCount, failureTokens };
  }
}
