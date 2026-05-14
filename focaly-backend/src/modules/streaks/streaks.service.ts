import { Injectable, NotFoundException } from '@nestjs/common';

import { StreaksRepository } from './streaks.repository';

@Injectable()
export class StreaksService {
  constructor(private readonly repository: StreaksRepository) {}

  async getStreak(userId: string) {
    const streak = await this.repository.findOrCreate(userId);
    if (!streak) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Streak not found.' });
    }
    return streak;
  }
}
