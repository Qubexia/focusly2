import { AiRateLimiterService } from '../../../src/modules/ai/ai-rate-limiter.service';

describe('AI rate limiter (FR-039)', () => {
  let redis: {
    zremrangebyscore: jest.Mock;
    zcard: jest.Mock;
    zrange: jest.Mock;
    get: jest.Mock;
    pipeline: jest.Mock;
  };
  let service: AiRateLimiterService;

  beforeEach(() => {
    redis = {
      zremrangebyscore: jest.fn().mockResolvedValue(0),
      zcard: jest.fn().mockResolvedValue(0),
      zrange: jest.fn().mockResolvedValue([]),
      get: jest.fn().mockResolvedValue(null),
      pipeline: jest.fn().mockReturnValue({
        zadd: jest.fn().mockReturnThis(),
        expire: jest.fn().mockReturnThis(),
        incr: jest.fn().mockReturnThis(),
        expireat: jest.fn().mockReturnThis(),
        exec: jest.fn().mockResolvedValue([]),
      }),
    };

    service = new AiRateLimiterService(redis as any);
  });

  it('allows request within limits', async () => {
    const result = await service.check('user-1');
    expect(result.allowed).toBe(true);
  });

  it('blocks when hourly limit exceeded', async () => {
    redis.zcard.mockResolvedValue(5);
    redis.zrange.mockResolvedValue([Date.now().toString(), (Date.now() - 1000).toString()]);

    const result = await service.check('user-1');
    expect(result.allowed).toBe(false);
    expect(result.retryAfterMs).toBeDefined();
    expect(result.retryAfterMs).toBeGreaterThan(0);
  });

  it('blocks when monthly limit exceeded', async () => {
    redis.zcard.mockResolvedValue(0);
    redis.get.mockResolvedValue('30');

    const result = await service.check('user-1');
    expect(result.allowed).toBe(false);
    expect(result.retryAfterMs).toBeDefined();
  });
});
