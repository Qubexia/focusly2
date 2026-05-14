import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { PlannedItemChangedEvent } from '../../../shared/events/planned-item-changed.event';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(PlannedItemChangedEvent)
export class PlannedItemChangedHandler implements IEventHandler<PlannedItemChangedEvent> {
  private readonly logger = new Logger(PlannedItemChangedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
  ) {}

  async handle(event: PlannedItemChangedEvent): Promise<void> {
    this.logger.log(`Planned item changed: ${event.itemId} kind=${event.kind}`);
  }
}
