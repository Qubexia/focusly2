const truthy = new Set(['1', 'true', 'yes', 'on']);

export const redisDisabled =
  truthy.has((process.env.FOCALY_DISABLE_REDIS ?? '').trim().toLowerCase());
