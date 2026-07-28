import { Injectable, NotFoundException } from '@nestjs/common';

import { resolveTimezone, todayKey, yesterdayKey } from '../../common/utils/day.util';
import { UsersRepository } from '../users/users.repository';

import { StreaksRepository } from './streaks.repository';

@Injectable()
export class StreaksService {
  constructor(
    private readonly repository: StreaksRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async getStreak(userId: string) {
    const streak = await this.repository.findOrCreate(userId);
    if (!streak) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Streak not found.' });
    }

    const user = await this.usersRepository.findActiveById(userId);
    const tz = resolveTimezone(user?.settings?.timezone);
    const current = this.resolveCurrent(streak.current, streak.lastActiveDate, tz);

    // The nightly cron is only a backstop; a broken streak has to read as zero
    // the moment the user's own midnight passes, not hours later.
    if (current !== streak.current) {
      const reset = await this.repository.resetStreak(userId);
      if (reset) reset.current = current;
    }

    return {
      current,
      longest: streak.longest,
      lastActiveDate: streak.lastActiveDate,
      // Milestone points live on the streak, task rewards on the user; the app
      // shows one wallet, so surface the sum.
      points: streak.points + (user?.totalPoints ?? 0),
      milestonePoints: streak.points,
      taskPoints: user?.totalPoints ?? 0,
      rewards: streak.rewards,
      timezone: tz,
    };
  }

  private resolveCurrent(current: number, lastActiveDate: string | null, tz: string): number {
    if (current <= 0 || !lastActiveDate) return current;
    if (lastActiveDate === todayKey(tz) || lastActiveDate === yesterdayKey(tz)) return current;
    return 0;
  }
}
