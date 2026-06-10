import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { SubscriptionChangedEvent } from '../../shared/events/subscription-changed.event';
import { AuditLog, AuditLogDocument } from '../auth/schemas/audit-log.schema';
import { UsersRepository } from '../users/users.repository';

import { PaymentEventsRepository } from './payment-events.repository';
import { SubscriptionStatus } from './schemas/subscription.schema';
import { SubscriptionsRepository } from './subscriptions.repository';

export interface ApplyEventInput {
  provider: 'stripe' | 'google_play' | 'app_store' | 'paymob';
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

    const paymentEventId = paymentEvent._id.toString();

    if (!isNew) {
      await this.paymentEventsRepo.markProcessed(paymentEventId, 'noop');
      return { outcome: 'noop' };
    }

    const existing = await this.subscriptionsRepo.findByProvider(
      input.provider,
      input.providerSubId,
    );

    if (existing && existing.lastEventAt && input.eventTimestamp <= existing.lastEventAt) {
      await this.paymentEventsRepo.markProcessed(paymentEventId, 'noop', 'out-of-order');
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

    await this.paymentEventsRepo.markProcessed(paymentEventId, 'applied');
    this.logger.log(`Subscription ${input.status} applied for user ${input.userId}`);

    return { outcome: 'applied' };
  }

  async getSubscription(userId: string) {
    await this.syncUserPlanFromSubscription(userId);
    return this.subscriptionsRepo.findByUserId(userId);
  }

  /**
   * Keeps User.plan aligned with the subscription row (fixes drift after cancel).
   */
  async syncUserPlanFromSubscription(userId: string): Promise<void> {
    const subscription = await this.subscriptionsRepo.findByUserId(userId);
    const user = await this.usersRepo.findActiveById(userId);
    if (!user) return;

    const now = new Date();
    const activeStatuses: SubscriptionStatus[] = ['active', 'trialing', 'past_due'];
    let shouldBePremium = false;
    let premiumUntil: Date | null = null;

    if (subscription && activeStatuses.includes(subscription.status)) {
      const periodEnd = subscription.currentPeriodEnd;
      if (!periodEnd || periodEnd.getTime() > now.getTime()) {
        shouldBePremium = true;
        premiumUntil = periodEnd ?? null;
      }
    }

    if (shouldBePremium) {
      const currentUntil = user.premiumUntil ? new Date(user.premiumUntil) : null;
      const needsUpdate =
        user.plan !== 'premium' ||
        (premiumUntil?.getTime() ?? null) !== (currentUntil?.getTime() ?? null);
      if (needsUpdate) {
        await this.usersRepo.updateById(userId, {
          $set: { plan: 'premium', premiumUntil },
        });
      }
      return;
    }

    if (user.plan !== 'free' || user.premiumUntil != null) {
      await this.usersRepo.updateById(userId, {
        $set: { plan: 'free', premiumUntil: null },
      });
    }
  }

  async activatePaymobFromSdk(
    userId: string,
    plan: 'monthly' | 'yearly',
    transactionId?: string,
  ): Promise<{ outcome: string; currentPeriodEnd: Date }> {
    const normalizedTx = transactionId?.trim() || `sdk-${Date.now()}`;
    const periodEnd = new Date();
    if (plan === 'yearly') {
      periodEnd.setFullYear(periodEnd.getFullYear() + 1);
    } else {
      periodEnd.setMonth(periodEnd.getMonth() + 1);
    }

    const result = await this.applyEvent({
      provider: 'paymob',
      eventId: `paymob-sdk-${normalizedTx}`,
      providerSubId: normalizedTx,
      userId,
      status: 'active',
      currentPeriodEnd: periodEnd,
      priceId: plan,
      eventTimestamp: new Date(),
      rawPayload: { source: 'native_sdk', plan },
    });

    return { outcome: result.outcome, currentPeriodEnd: periodEnd };
  }

  async cancelSubscription(userId: string): Promise<{
    status: 'canceled';
    currentPeriodEnd: Date | null;
    accessUntil: Date | null;
    message: string;
  }> {
    const existing = await this.subscriptionsRepo.findByUserId(userId);
    if (!existing) {
      throw new NotFoundException({ message: 'No subscription found.' });
    }

    const now = new Date();
    const wasActive = ['active', 'trialing', 'past_due'].includes(existing.status);

    if (wasActive) {
      await this.subscriptionsRepo.updateByUserId(userId, {
        $set: {
          status: 'canceled',
          lastEventAt: now,
          currentPeriodEnd: now,
        },
      });

      this.eventBus.publish(
        new SubscriptionChangedEvent(userId, 'canceled', null, existing.provider),
      );

      await this.auditLogModel.create({
        userId,
        actor: 'user',
        eventType: 'plan.canceled',
        data: { provider: existing.provider, accessUntil: null },
      });
    }

    await this.syncUserPlanFromSubscription(userId);

    const message = wasActive
      ? 'Subscription canceled. Premium access has ended.'
      : 'Subscription was already canceled. Premium access has been updated.';

    this.logger.log(`Subscription canceled for user ${userId}`);

    return {
      status: 'canceled',
      currentPeriodEnd: now,
      accessUntil: null,
      message,
    };
  }
}
