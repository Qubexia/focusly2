import { Logger } from '@nestjs/common';
import { EventsHandler, IEventHandler } from '@nestjs/cqrs';

import { RewardUnlockedEvent } from '../../../shared/events/reward-unlocked.event';
import { NotificationSchedulerService } from '../notification-scheduler.service';

@EventsHandler(RewardUnlockedEvent)
export class RewardUnlockedHandler implements IEventHandler<RewardUnlockedEvent> {
  private readonly logger = new Logger(RewardUnlockedHandler.name);

  constructor(
    private readonly scheduler: NotificationSchedulerService,
  ) {}

  async handle(event: RewardUnlockedEvent): Promise<void> {
    await this.scheduler.scheduleRewardNotification(event.userId, event.code, event.points);
    this.logger.log(`Reward notification scheduled for user ${event.userId}: ${event.code}`);
  }
}
