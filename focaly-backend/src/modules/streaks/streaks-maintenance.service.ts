import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

import { UsersRepository } from '../users/users.repository';
import { StreaksRepository } from './streaks.repository';

dayjs.extend(utc);
dayjs.extend(timezone);

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

      const tz = userRecord.settings?.timezone || 'UTC';
      const todayLocal = dayjs().tz(tz).format('YYYY-MM-DD');

      if (streak.lastActiveDate && streak.lastActiveDate < todayLocal) {
        const yesterdayLocal = dayjs().tz(tz).subtract(1, 'day').format('YYYY-MM-DD');
        if (streak.lastActiveDate !== yesterdayLocal) {
          await this.streaksRepository.resetStreak(streak.userId.toString());
          resetCount++;
        }
      }
    }

    this.logger.log(`Streak-reset cron finished. Reset ${resetCount} streaks.`);
  }
}
