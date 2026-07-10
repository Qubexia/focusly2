import { Injectable, Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import dayjs from 'dayjs';

import { PomodoroCompletedEvent } from '../../../shared/events/pomodoro-completed.event';
import { AnalyticsRepository } from '../analytics.repository';

@Injectable()
@EventsHandler(PomodoroCompletedEvent)
export class PomodoroCompletedAnalyticsHandler implements IEventHandler<PomodoroCompletedEvent> {
  private readonly logger = new Logger(PomodoroCompletedAnalyticsHandler.name);

  constructor(private readonly analyticsRepo: AnalyticsRepository) {}

  async handle(event: PomodoroCompletedEvent): Promise<void> {
    if (event.totalFocusMinutes <= 0) return;

    const date = dayjs(event.completedAt).startOf('day').toDate();
    await this.analyticsRepo.upsertDay(event.userId, date, {
      focusMinutes: event.totalFocusMinutes,
      completedCycles: event.completedCycles,
      plannedItemsCompleted: 0,
      sessionsCount: 1,
    });

    this.logger.debug(
      `Updated analytics for user ${event.userId}: +${event.totalFocusMinutes} focus minutes`,
    );
  }
}
