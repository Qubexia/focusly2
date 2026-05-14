import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BullModule, getQueueToken } from '@nestjs/bullmq';
import { URL } from 'url';

import { redisDisabled } from '../../config/runtime-flags';
import { ALL_QUEUES } from './queue.constants';

const noopQueue = {
  add: async () => null,
};

const queueProviders = ALL_QUEUES.map((name) => ({
  provide: getQueueToken(name),
  useValue: noopQueue,
}));

@Global()
@Module({
  imports: redisDisabled
    ? []
    : [
        BullModule.forRootAsync({
          inject: [ConfigService],
          useFactory: (config: ConfigService) => {
            const url = new URL(config.getOrThrow<string>('redis.url'));
            return {
              connection: {
                host: url.hostname,
                port: Number(url.port || 6379),
                username: url.username || undefined,
                password: url.password || undefined,
                tls: url.protocol === 'rediss:' ? {} : undefined,
              },
            };
          },
        }),
        ...ALL_QUEUES.map((name) => BullModule.registerQueue({ name })),
      ],
  providers: redisDisabled ? queueProviders : [],
  exports: redisDisabled ? queueProviders : [BullModule],
})
export class QueueModule {}
