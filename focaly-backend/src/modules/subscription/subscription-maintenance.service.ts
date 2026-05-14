import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { SubscriptionsRepository } from './subscriptions.repository';
import { SubscriptionsService } from './subscriptions.service';

@Injectable()
export class SubscriptionMaintenanceService {
  private readonly logger = new Logger(SubscriptionMaintenanceService.name);

  constructor(
    private readonly subscriptionsRepo: SubscriptionsRepository,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  @Cron(CronExpression.EVERY_6_HOURS)
  async recheckActiveSubscriptions(): Promise<void> {
    this.logger.log('Running IAP re-check cron...');
    const active = await this.subscriptionsRepo.findAllActive();
    this.logger.log(`Found ${active.length} active subscriptions to re-check`);
  }
}
