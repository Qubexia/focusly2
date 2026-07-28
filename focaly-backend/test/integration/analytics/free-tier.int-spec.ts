import { ForbiddenException } from '@nestjs/common';
import dayjs from 'dayjs';

import { AnalyticsController } from '../../../src/modules/analytics/analytics.controller';
import { AnalyticsService } from '../../../src/modules/analytics/analytics.service';
import { PlatformSettingsService } from '../../../src/modules/platform-settings/platform-settings.service';
import { UsersRepository } from '../../../src/modules/users/users.repository';

describe('Analytics free-tier range gate', () => {
  const freeUser = {
    id: 'u1',
    plan: 'free' as const,
    emailVerified: true,
    role: 'user',
    sessionId: 's1',
    email: 'test@test.com',
  };

  const buildController = (premiumGatingEnabled: boolean): AnalyticsController => {
    const service = {} as AnalyticsService;
    const platformSettings = {
      resolve: jest.fn().mockResolvedValue({ premiumGatingEnabled }),
    } as unknown as PlatformSettingsService;
    const usersRepo = {
      findActiveById: jest.fn().mockResolvedValue({ settings: { timezone: 'UTC' } }),
    } as unknown as UsersRepository;

    return new AnalyticsController(service, platformSettings, usersRepo);
  };

  /** enforceRange is private on the controller; reach it through a typed view. */
  type RangeEnforcer = {
    enforceRange: (user: typeof freeUser, from: Date, to: Date) => Promise<void>;
  };

  const enforce = (controller: AnalyticsController, from: string, to: string, user = freeUser) =>
    (controller as unknown as RangeEnforcer).enforceRange(
      user,
      dayjs(from).startOf('day').toDate(),
      dayjs(to).endOf('day').toDate(),
    );

  it('free user requesting current week range passes', async () => {
    const controller = buildController(true);
    const today = dayjs();

    await expect(
      enforce(controller, today.startOf('week').format('YYYY-MM-DD'), today.format('YYYY-MM-DD')),
    ).resolves.toBeUndefined();
  });

  it('free user requesting wider range → 403', async () => {
    const controller = buildController(true);

    await expect(enforce(controller, '2024-01-01', '2024-12-31')).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('free user passes any range when premium gating is switched off', async () => {
    const controller = buildController(false);

    await expect(enforce(controller, '2024-01-01', '2024-12-31')).resolves.toBeUndefined();
  });

  it('premium user any range passes', async () => {
    const controller = buildController(true);

    await expect(
      enforce(controller, '2020-01-01', '2025-12-31', {
        ...freeUser,
        plan: 'premium' as never,
        premiumUntil: new Date(Date.now() + 86_400_000),
      } as never),
    ).resolves.toBeUndefined();
  });
});
