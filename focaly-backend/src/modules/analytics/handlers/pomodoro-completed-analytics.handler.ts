import { Injectable, Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { dayjs, localDayKey, resolveTimezone } from '../../../common/utils/day.util';
import { PomodoroCompletedEvent } from '../../../shared/events/pomodoro-completed.event';
import { UsersRepository } from '../../users/users.repository';
import { AnalyticsRepository } from '../analytics.repository';

@Injectable()
@EventsHandler(PomodoroCompletedEvent)
export class PomodoroCompletedAnalyticsHandler implements IEventHandler<PomodoroCompletedEvent> {
  private readonly logger = new Logger(PomodoroCompletedAnalyticsHandler.name);

  constructor(
    private readonly analyticsRepo: AnalyticsRepository,
    private readonly usersRepo: UsersRepository,
  ) {}

  async handle(event: PomodoroCompletedEvent): Promise<void> {
    if (event.totalFocusMinutes <= 0) return;

    const user = await this.usersRepo.findActiveById(event.userId);
    const tz = resolveTimezone(user?.settings?.timezone);
    // Bucket by the user's own day, so a session finished at 1am counts for
    // that night — not for the day before, as UTC would have it.
    const dayKey = localDayKey(event.completedAt, tz);

    await this.analyticsRepo.upsertDay(event.userId, dayjs(`${dayKey}T00:00:00Z`).toDate(), {
      focusMinutes: event.totalFocusMinutes,
      completedCycles: event.completedCycles,
      plannedItemsCompleted: 0,
      sessionsCount: 1,
    });

    this.logger.debug(
      `Updated analytics for user ${event.userId} on ${dayKey}: +${event.totalFocusMinutes} focus minutes`,
    );
  }
}
