import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { FcmFakeClient } from './fcm-fake.client';
import { FcmRealClient } from './fcm.client';
import { FCM_CLIENT } from './fcm.tokens';

@Global()
@Module({
  providers: [
    FcmFakeClient,
    FcmRealClient,
    {
      provide: FCM_CLIENT,
      inject: [ConfigService, FcmRealClient, FcmFakeClient],
      useFactory: (config: ConfigService, real: FcmRealClient, fake: FcmFakeClient) =>
        config.get<string>('fcm.serviceAccountJson') ? real : fake,
    },
  ],
  exports: [FCM_CLIENT],
})
export class FcmModule {}
