import { Inject, Injectable } from '@nestjs/common';
import Redis from 'ioredis';
import dayjs from 'dayjs';

import { REDIS_CLIENT } from '../../infrastructure/redis/redis.tokens';

const HOURLY_CAPACITY = 5;
const HOURLY_WINDOW_MS = 3600_000;
const MONTHLY_CAPACITY = 30;

@Injectable()
export class AiRateLimiterService {
  constructor(
    @Inject(REDIS_CLIENT)
    private readonly redis: Redis,
  ) {}

  async check(userId: string): Promise<{ allowed: boolean; retryAfterMs?: number }> {
    const now = Date.now();
    const hourKey = `ai:user:${userId}:hour`;
    const monthKey = `ai:user:${userId}:month:${dayjs().format('YYYYMM')}`;

    const hourWindow = now - HOURLY_WINDOW_MS;
    await this.redis.zremrangebyscore(hourKey, 0, hourWindow);
    const hourCount = await this.redis.zcard(hourKey);

    if (hourCount >= HOURLY_CAPACITY) {
      const oldest = await this.redis.zrange(hourKey, 0, 0, 'WITHSCORES');
      const resetAt = oldest[1] ? Number(oldest[1]) + HOURLY_WINDOW_MS : now + HOURLY_WINDOW_MS;
      return { allowed: false, retryAfterMs: resetAt - now };
    }

    const monthCount = await this.redis.get(monthKey);
    if (monthCount && Number(monthCount) >= MONTHLY_CAPACITY) {
      const nextMonth = dayjs().endOf('month').add(1, 'ms').valueOf();
      return { allowed: false, retryAfterMs: nextMonth - now };
    }

    return { allowed: true };
  }

  async increment(userId: string): Promise<void> {
    const now = Date.now();
    const hourKey = `ai:user:${userId}:hour`;
    const monthKey = `ai:user:${userId}:month:${dayjs().format('YYYYMM')}`;

    const pipeline = this.redis.pipeline();
    pipeline.zadd(hourKey, now, `${now}-${Math.random()}`);
    pipeline.expire(hourKey, Math.ceil(HOURLY_WINDOW_MS / 1000));
    pipeline.incr(monthKey);
    pipeline.expireat(monthKey, dayjs().endOf('month').add(1, 's').unix());
    await pipeline.exec();
  }
}
