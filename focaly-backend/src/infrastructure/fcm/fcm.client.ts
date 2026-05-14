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
    const json = this.config.get<string>('fcm.serviceAccountJson');
    if (!json) {
      this.logger.warn('FCM_SERVICE_ACCOUNT_JSON is empty — real FCM client will not initialize.');
      return;
    }
    const credentials = JSON.parse(json) as admin.ServiceAccount;
    this.app = admin.initializeApp({ credential: admin.credential.cert(credentials) }, 'focaly');
  }

  async send(messages: FcmMessage[]): Promise<FcmSendResult> {
    if (!this.app) {
      throw new Error('FCM client not initialized; check FCM_SERVICE_ACCOUNT_JSON');
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
