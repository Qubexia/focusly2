import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { PlannedItemChangedEvent } from '../../../shared/events/planned-item-changed.event';
import { PlannedItemsRepository } from '../../planned-items/planned-items.repository';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(PlannedItemChangedEvent)
export class PlannedItemChangedHandler implements IEventHandler<PlannedItemChangedEvent> {
  private readonly logger = new Logger(PlannedItemChangedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
    private readonly plannedItemsRepository: PlannedItemsRepository,
  ) {}

  async handle(event: PlannedItemChangedEvent): Promise<void> {
    const item = await this.plannedItemsRepository.findById(event.itemId);
    if (!item || item.userId.toString() !== event.userId) {
      this.logger.warn(`Planned item ${event.itemId} not found for notification sync`);
      return;
    }

    await this.scheduler.syncPlannedItemReminders({
      userId: event.userId,
      id: event.itemId,
      title: item.title,
      plannedAt: item.plannedAt,
      reminderMinutesBefore: item.reminderMinutesBefore,
      reminderEnabled: item.reminderEnabled,
      completed: item.completed,
    });

    this.logger.log(`Synced notification jobs for planned item ${event.itemId} (${event.kind})`);
  }
}
