import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { resolveTimezone, todayKey, yesterdayKey } from '../../common/utils/day.util';
import { UsersRepository } from '../users/users.repository';

import { StreaksRepository } from './streaks.repository';

@Injectable()
export class StreaksMaintenanceService {
  private readonly logger = new Logger(StreaksMaintenanceService.name);

  constructor(
    private readonly streaksRepository: StreaksRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async resetStaleStreaks(): Promise<void> {
    this.logger.log('Running daily streak-reset cron...');

    const streaks = await this.streaksRepository.findAllWithLastActive();
    let resetCount = 0;

    for (const streak of streaks) {
      const userRecord = await this.usersRepository.findActiveById(streak.userId.toString());
      if (!userRecord) continue;

      const tz = resolveTimezone(userRecord.settings?.timezone);
      const todayLocal = todayKey(tz);

      if (streak.lastActiveDate && streak.lastActiveDate < todayLocal) {
        const yesterdayLocal = yesterdayKey(tz);
        if (streak.lastActiveDate !== yesterdayLocal) {
          await this.streaksRepository.resetStreak(streak.userId.toString());
          resetCount++;
        }
      }
    }

    this.logger.log(`Streak-reset cron finished. Reset ${resetCount} streaks.`);
  }
}
