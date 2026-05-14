import { InjectModel } from '@nestjs/mongoose';
import { Injectable, Logger } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';
import { Model } from 'mongoose';

import { SubscriptionChangedEvent } from '../../shared/events/subscription-changed.event';
import { AuditLog, AuditLogDocument } from '../auth/schemas/audit-log.schema';
import { UsersRepository } from '../users/users.repository';

import { PaymentEventsRepository } from './payment-events.repository';
import { SubscriptionStatus } from './schemas/subscription.schema';
import { SubscriptionsRepository } from './subscriptions.repository';

export interface ApplyEventInput {
  provider: 'stripe' | 'google_play' | 'app_store';
  eventId: string;
  providerSubId: string;
  userId: string;
  status: SubscriptionStatus;
  currentPeriodEnd?: Date | null;
  priceId?: string | null;
  eventTimestamp: Date;
  rawPayload: Record<string, unknown>;
}

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(
    private readonly subscriptionsRepo: SubscriptionsRepository,
    private readonly paymentEventsRepo: PaymentEventsRepository,
    private readonly usersRepo: UsersRepository,
    private readonly eventBus: EventBus,
    @InjectModel(AuditLog.name) private readonly auditLogModel: Model<AuditLogDocument>,
  ) {}

  async applyEvent(input: ApplyEventInput): Promise<{ outcome: string }> {
    const { event: paymentEvent, isNew } = await this.paymentEventsRepo.insertIdempotent({
      provider: input.provider,
      eventId: input.eventId,
      userId: input.userId,
      payload: input.rawPayload,
    });

    if (!isNew) {
      await this.paymentEventsRepo.markProcessed(paymentEvent.id, 'noop');
      return { outcome: 'noop' };
    }

    const existing = await this.subscriptionsRepo.findByProvider(
      input.provider,
      input.providerSubId,
    );

    if (existing && existing.lastEventAt && input.eventTimestamp <= existing.lastEventAt) {
      await this.paymentEventsRepo.markProcessed(paymentEvent.id, 'noop', 'out-of-order');
      return { outcome: 'noop' };
    }

    await this.subscriptionsRepo.upsert(input.userId, {
      userId: input.userId,
      provider: input.provider,
      providerSubId: input.providerSubId,
      status: input.status,
      currentPeriodEnd: input.currentPeriodEnd ?? null,
      priceId: input.priceId ?? null,
      lastEventAt: input.eventTimestamp,
    });

    const planMapping: Record<string, 'free' | 'premium'> = {
      trialing: 'premium',
      active: 'premium',
      past_due: 'premium',
      canceled: 'free',
      expired: 'free',
    };

    const newPlan = planMapping[input.status] ?? 'free';
    const userUpdate: Record<string, unknown> = { plan: newPlan };

    if (newPlan === 'premium') {
      userUpdate.premiumUntil = input.currentPeriodEnd ?? null;
    } else {
      userUpdate.premiumUntil = null;
    }

    await this.usersRepo.updateById(input.userId, { $set: userUpdate });

    this.eventBus.publish(
      new SubscriptionChangedEvent(
        input.userId,
        input.status,
        input.currentPeriodEnd ?? null,
        input.provider,
      ),
    );

    await this.auditLogModel.create({
      userId: input.userId,
      actor: 'webhook',
      eventType: `plan.${input.status}`,
      data: { provider: input.provider, status: input.status },
    });

    await this.paymentEventsRepo.markProcessed(paymentEvent.id, 'applied');
    this.logger.log(`Subscription ${input.status} applied for user ${input.userId}`);

    return { outcome: 'applied' };
  }

  async getSubscription(userId: string) {
    return this.subscriptionsRepo.findByUserId(userId);
  }
}
