import { Controller, Get, Inject } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckResult,
  HealthCheckService,
  HealthIndicatorResult,
  HealthIndicatorStatus,
  MongooseHealthIndicator,
} from '@nestjs/terminus';
import { ApiTags } from '@nestjs/swagger';
import type Redis from 'ioredis';

import { Public } from '../../common/decorators/public.decorator';
import { REDIS_CLIENT } from '../../infrastructure/redis/redis.tokens';
import { FCM_CLIENT, FcmClient } from '../../infrastructure/fcm/fcm.tokens';

@ApiTags('Health')
@Controller({ path: 'health', version: '1' })
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly mongoose: MongooseHealthIndicator,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    @Inject(FCM_CLIENT) private readonly fcm: FcmClient,
  ) {}

  @Get()
  @Public()
  liveness(): { status: 'ok' } {
    return { status: 'ok' };
  }

  @Get('ready')
  @Public()
  @HealthCheck()
  async readiness(): Promise<HealthCheckResult> {
    return this.health.check([
      () => this.mongoose.pingCheck('db'),
      () => this.pingRedis(),
      () => this.pingFcm(),
    ]);
  }

  private async pingRedis(): Promise<HealthIndicatorResult> {
    const status: HealthIndicatorStatus = (await this.redis.ping()) === 'PONG' ? 'up' : 'down';
    return { redis: { status } };
  }

  private async pingFcm(): Promise<HealthIndicatorResult> {
    const status: HealthIndicatorStatus = typeof this.fcm.send === 'function' ? 'up' : 'down';
    return { fcm: { status } };
  }
}
