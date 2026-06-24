import { Injectable, Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { EventBus } from '@nestjs/cqrs';
import dayjs from 'dayjs';
import timezone from 'dayjs/plugin/timezone';
import utc from 'dayjs/plugin/utc';

import { PomodoroCompletedEvent } from '../../../shared/events/pomodoro-completed.event';
import { RewardCode, RewardUnlockedEvent } from '../../../shared/events/reward-unlocked.event';
import { StudyDayCompletedEvent } from '../../../shared/events/study-day-completed.event';
import { UsersRepository } from '../../users/users.repository';
import { StreaksRepository } from '../streaks.repository';

dayjs.extend(utc);
dayjs.extend(timezone);

const MILESTONES = [3, 7, 30, 100] as const;
const MILESTONE_MAP: Record<number, RewardCode> = {
  3: 'STREAK_3',
  7: 'STREAK_7',
  30: 'STREAK_30',
  100: 'STREAK_100',
};

@Injectable()
@EventsHandler(PomodoroCompletedEvent, StudyDayCompletedEvent)
export class AdvanceStreakHandler implements IEventHandler<
  PomodoroCompletedEvent | StudyDayCompletedEvent
> {
  private readonly logger = new Logger(AdvanceStreakHandler.name);

  constructor(
    private readonly streaksRepository: StreaksRepository,
    private readonly usersRepository: UsersRepository,
    private readonly eventBus: EventBus,
  ) {}

  async handle(event: PomodoroCompletedEvent | StudyDayCompletedEvent): Promise<void> {
    // A pomodoro only counts if it was a real study chunk; a completed study
    // schedule occurrence always counts.
    if (
      event instanceof PomodoroCompletedEvent &&
      (event.focusMinutes < 10 || event.completedCycles < 1)
    ) {
      return;
    }

    const user = await this.usersRepository.findActiveById(event.userId);
    if (!user) return;

    const tz = user.settings?.timezone || 'UTC';
    const todayLocal = dayjs().tz(tz).format('YYYY-MM-DD');
    const yesterdayLocal = dayjs().tz(tz).subtract(1, 'day').format('YYYY-MM-DD');

    const streak = await this.streaksRepository.findOrCreate(event.userId);

    if (streak.lastActiveDate === todayLocal) return;

    let newCurrent: number;
    if (streak.lastActiveDate === null) {
      newCurrent = 1;
    } else if (streak.lastActiveDate === yesterdayLocal) {
      newCurrent = streak.current + 1;
    } else {
      newCurrent = 1;
    }

    const newLongest = Math.max(streak.longest, newCurrent);
    const rewardCode = this.checkMilestone(newCurrent, streak.rewards);
    const pointsGained = rewardCode ? this.pointsForMilestone(newCurrent) : 0;
    const newRewards = rewardCode
      ? [...(streak.rewards || []), { code: rewardCode, awardedAt: new Date() }]
      : streak.rewards;
    const newPoints = streak.points + pointsGained;

    const updatedStreak = await this.streaksRepository.updateStreak(event.userId, {
      current: newCurrent,
      longest: newLongest,
      lastActiveDate: todayLocal,
      points: newPoints,
      rewards: newRewards,
    });

    if (rewardCode && updatedStreak) {
      this.logger.log(`Reward ${rewardCode} unlocked for user ${event.userId}`);
      this.eventBus.publish(
        new RewardUnlockedEvent(event.userId, rewardCode, pointsGained, new Date()),
      );
    }
  }

  private checkMilestone(
    current: number,
    existingRewards: Array<{ code: string; awardedAt: Date }> | undefined,
  ): RewardCode | null {
    const existingCodes = new Set((existingRewards || []).map((r) => r.code));
    for (const ms of MILESTONES) {
      if (current === ms && !existingCodes.has(MILESTONE_MAP[ms]!)) {
        return MILESTONE_MAP[ms]!;
      }
    }
    return null;
  }

  private pointsForMilestone(current: number): number {
    if (current === 3) return 50;
    if (current === 7) return 150;
    if (current === 30) return 500;
    if (current === 100) return 2000;
    return 0;
  }
}
