import { existsSync } from 'node:fs';

import { Module, Global, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { FcmFakeClient } from './fcm-fake.client';
import { FcmRealClient } from './fcm.client';
import { FCM_CLIENT } from './fcm.tokens';

const fcmModuleLogger = new Logger('FcmModule');

function hasUsableFcmCredentials(config: ConfigService): boolean {
  const inlineJson = config.get<string>('fcm.serviceAccountJson')?.trim();
  if (inlineJson) return true;

  const jsonPath = config.get<string>('fcm.serviceAccountPath')?.trim();
  if (!jsonPath) return false;

  if (!existsSync(jsonPath)) {
    fcmModuleLogger.warn(
      `FCM_SERVICE_ACCOUNT_PATH does not exist (${jsonPath}); using fake push client.`,
    );
    return false;
  }

  return true;
}

@Global()
@Module({
  providers: [
    FcmFakeClient,
    FcmRealClient,
    {
      provide: FCM_CLIENT,
      inject: [ConfigService, FcmRealClient, FcmFakeClient],
      useFactory: (config: ConfigService, real: FcmRealClient, fake: FcmFakeClient) =>
        hasUsableFcmCredentials(config) ? real : fake,
    },
  ],
  exports: [FCM_CLIENT],
})
export class FcmModule {}
