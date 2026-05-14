import { ForbiddenException } from '@nestjs/common';
import dayjs from 'dayjs';

import { AnalyticsController } from '../../../src/modules/analytics/analytics.controller';
import { AnalyticsService } from '../../../src/modules/analytics/analytics.service';

describe('Analytics free-tier range gate', () => {
  let controller: AnalyticsController;

  beforeEach(() => {
    const service = {} as AnalyticsService;
    controller = new AnalyticsController(service);
  });

  it('free user requesting current week range passes', () => {
    const today = dayjs();
    const from = today.startOf('week').format('YYYY-MM-DD');
    const to = today.format('YYYY-MM-DD');

    expect(() =>
      (controller as any).enforceRange(
        { id: 'u1', plan: 'free', emailVerified: true, role: 'user', sessionId: 's1', email: 'test@test.com' },
        from,
        to,
      ),
    ).not.toThrow();
  });

  it('free user requesting wider range → 403', () => {
    expect(() =>
      (controller as any).enforceRange(
        { id: 'u1', plan: 'free', emailVerified: true, role: 'user', sessionId: 's1', email: 'test@test.com' },
        '2024-01-01',
        '2024-12-31',
      ),
    ).toThrow(ForbiddenException);
  });

  it('premium user any range passes', () => {
    expect(() =>
      (controller as any).enforceRange(
        { id: 'u1', plan: 'premium', premiumUntil: new Date(Date.now() + 86400_000), emailVerified: true, role: 'user', sessionId: 's1', email: 'test@test.com' },
        '2020-01-01',
        '2025-12-31',
      ),
    ).not.toThrow();
  });
});
