import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { ScheduleChangedEvent } from '../../../shared/events/schedule-changed.event';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(ScheduleChangedEvent)
export class ScheduleChangedHandler implements IEventHandler<ScheduleChangedEvent> {
  private readonly logger = new Logger(ScheduleChangedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
  ) {}

  async handle(event: ScheduleChangedEvent): Promise<void> {
    this.logger.log(`Schedule changed: ${event.scheduleId}`);
  }
}
