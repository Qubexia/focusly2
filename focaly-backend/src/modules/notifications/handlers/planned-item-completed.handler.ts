import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { PlannedItemCompletedEvent } from '../../../shared/events/planned-item-completed.event';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(PlannedItemCompletedEvent)
export class PlannedItemCompletedHandler implements IEventHandler<PlannedItemCompletedEvent> {
  private readonly logger = new Logger(PlannedItemCompletedHandler.name);

  constructor(private readonly scheduler: NotificationSchedulerService) {}

  async handle(event: PlannedItemCompletedEvent): Promise<void> {
    await this.scheduler.cancelByRef('planned_item', event.itemId);
    this.logger.log(`Cancelled notification jobs for completed item ${event.itemId}`);
  }
}
