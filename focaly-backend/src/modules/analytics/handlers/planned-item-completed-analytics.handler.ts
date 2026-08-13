import { Injectable, Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { dayjs } from '../../../common/utils/day.util';
import { PlannedItemCompletedEvent } from '../../../shared/events/planned-item-completed.event';
import { AnalyticsRepository } from '../analytics.repository';

/**
 * Keeps the daily rollup's completed-task counter live. Without this the
 * counter stays at zero until the nightly rollup — and used to stay at zero
 * forever, because nothing ever incremented it.
 */
@Injectable()
@EventsHandler(PlannedItemCompletedEvent)
export class PlannedItemCompletedAnalyticsHandler implements IEventHandler<PlannedItemCompletedEvent> {
  private readonly logger = new Logger(PlannedItemCompletedAnalyticsHandler.name);

  constructor(private readonly analyticsRepo: AnalyticsRepository) {}

  async handle(event: PlannedItemCompletedEvent): Promise<void> {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(event.occurrenceDate)) return;

    await this.analyticsRepo.upsertDay(
      event.userId,
      dayjs(`${event.occurrenceDate}T00:00:00Z`).toDate(),
      {
        focusMinutes: 0,
        completedCycles: 0,
        plannedItemsCompleted: 1,
        sessionsCount: 0,
      },
    );

    this.logger.debug(
      `Counted completed ${event.kind} for user ${event.userId} on ${event.occurrenceDate}`,
    );
  }
}
