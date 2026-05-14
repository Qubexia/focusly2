import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { PlannedItemDeletedEvent } from '../../../shared/events/planned-item-deleted.event';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(PlannedItemDeletedEvent)
export class PlannedItemDeletedHandler implements IEventHandler<PlannedItemDeletedEvent> {
  private readonly logger = new Logger(PlannedItemDeletedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
  ) {}

  async handle(event: PlannedItemDeletedEvent): Promise<void> {
    await this.scheduler.cancelByRef('planned_item', event.itemId);
    this.logger.log(`Cancelled notification jobs for planned item ${event.itemId}`);
  }
}
