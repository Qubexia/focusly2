import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client } from '@aws-sdk/client-s3';

import { S3_CLIENT } from './s3.tokens';

@Global()
@Module({
  providers: [
    {
      provide: S3_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService): S3Client => {
        const endpoint = config.get<string>('s3.endpoint');
        return new S3Client({
          region: config.getOrThrow<string>('s3.region'),
          credentials:
            config.get<string>('s3.accessKeyId') && config.get<string>('s3.secretAccessKey')
              ? {
                  accessKeyId: config.getOrThrow<string>('s3.accessKeyId'),
                  secretAccessKey: config.getOrThrow<string>('s3.secretAccessKey'),
                }
              : undefined,
          endpoint: endpoint ? endpoint : undefined,
          forcePathStyle: Boolean(endpoint),
        });
      },
    },
  ],
  exports: [S3_CLIENT],
})
export class StorageModule {}
