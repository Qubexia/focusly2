import { Module, Global, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import RedisMock from 'ioredis-mock';

import { REDIS_CLIENT } from './redis.tokens';

@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Redis => {
        const redisDisabled = config.get<boolean>('FOCALY_DISABLE_REDIS', false);
        if (redisDisabled) {
          return new RedisMock() as unknown as Redis;
        }

        const url = config.getOrThrow<string>('redis.url');
        const client = new Redis(url, {
          maxRetriesPerRequest: null,
          enableReadyCheck: true,
          // Use lazyConnect so the app doesn't immediately fail at startup
          // if Redis isn't available locally. Consumers can call `connect()`
          // when they actually need the connection.
          lazyConnect: true,
        });

        // Prevent unhandled 'error' events from crashing the process.
        client.on('error', (err) => {
          // Keep the log concise and non-fatal; real reconnection is handled by ioredis.
          // This avoids noisy "Unhandled error event" logs when Redis is down.
          // eslint-disable-next-line no-console
          console.error('[ioredis] client error:', err?.message ?? err);
        });

        return client;
      },
    },
  ],
  exports: [REDIS_CLIENT],
})
export class RedisModule implements OnModuleDestroy {
  constructor() {}

  async onModuleDestroy(): Promise<void> {
    // ioredis cleans up via process exit; the explicit quit lives where the client is owned.
  }
}
