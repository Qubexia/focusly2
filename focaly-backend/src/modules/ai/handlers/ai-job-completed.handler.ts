import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { AiJobCompletedEvent } from '../../../shared/events/ai-job-completed.event';
import { NotificationsRepository } from '../../notifications/notifications.repository';

@EventsHandler(AiJobCompletedEvent)
export class AiJobCompletedHandler implements IEventHandler<AiJobCompletedEvent> {
  private readonly logger = new Logger(AiJobCompletedHandler.name);

  constructor(
    private readonly notificationsRepo: NotificationsRepository,
  ) {}

  async handle(event: AiJobCompletedEvent): Promise<void> {
    await this.notificationsRepo.create({
      userId: event.userId,
      type: 'system',
      title: 'AI Notes Ready',
      body: 'Your lecture notes have been processed.',
    });
    this.logger.log(`AI notification created for user ${event.userId}`);
  }
}
