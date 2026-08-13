import { EventBus } from '@nestjs/cqrs';
import { Model } from 'mongoose';

import { AuditLogDocument } from '../../../src/modules/auth/schemas/audit-log.schema';
import { PaymentEventsRepository } from '../../../src/modules/subscription/payment-events.repository';
import { PaymentEventDocument } from '../../../src/modules/subscription/schemas/payment-event.schema';
import { SubscriptionsRepository } from '../../../src/modules/subscription/subscriptions.repository';
import { SubscriptionsService } from '../../../src/modules/subscription/subscriptions.service';
import { UsersRepository } from '../../../src/modules/users/users.repository';

type InsertIdempotentResult = Awaited<ReturnType<PaymentEventsRepository['insertIdempotent']>>;

/** Only `_id` is read by the service, which stringifies it for markProcessed(). */
function insertedEvent(id: string): InsertIdempotentResult {
  return {
    event: { _id: id } as unknown as PaymentEventDocument,
    isNew: true,
  };
}

describe('Subscription plan mirroring (T140)', () => {
  let service: SubscriptionsService;
  let subsRepo: jest.Mocked<SubscriptionsRepository>;
  let payEventsRepo: jest.Mocked<PaymentEventsRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let eventBus: jest.Mocked<EventBus>;

  beforeEach(() => {
    subsRepo = {
      findByProvider: jest.fn(),
      upsert: jest.fn(),
    } as unknown as jest.Mocked<SubscriptionsRepository>;
    payEventsRepo = {
      insertIdempotent: jest.fn(),
      markProcessed: jest.fn(),
    } as unknown as jest.Mocked<PaymentEventsRepository>;
    usersRepo = {
      updateById: jest.fn(),
    } as unknown as jest.Mocked<UsersRepository>;
    eventBus = { publish: jest.fn() } as unknown as jest.Mocked<EventBus>;

    const auditLogModel = { create: jest.fn() } as unknown as Model<AuditLogDocument>;
    service = new SubscriptionsService(subsRepo, payEventsRepo, usersRepo, eventBus, auditLogModel);
  });

  it('applyEvent("canceled") flips User.plan to free and clears premiumUntil', async () => {
    payEventsRepo.insertIdempotent.mockResolvedValue(insertedEvent('pe-1'));
    subsRepo.findByProvider.mockResolvedValue(null);

    await service.applyEvent({
      provider: 'paymob',
      eventId: 'evt_cancel',
      providerSubId: 'sub_123',
      userId: 'user-1',
      status: 'canceled',
      eventTimestamp: new Date(),
      rawPayload: {},
    });

    expect(usersRepo.updateById).toHaveBeenCalledWith('user-1', {
      $set: { plan: 'free', premiumUntil: null },
    });
    expect(payEventsRepo.markProcessed).toHaveBeenCalledWith('pe-1', 'applied');
  });

  it('applyEvent("active") flips User.plan to premium', async () => {
    payEventsRepo.insertIdempotent.mockResolvedValue(insertedEvent('pe-2'));
    subsRepo.findByProvider.mockResolvedValue(null);
    const periodEnd = new Date(Date.now() + 30 * 86400_000);

    await service.applyEvent({
      provider: 'paymob',
      eventId: 'evt_active',
      providerSubId: 'sub_456',
      userId: 'user-2',
      status: 'active',
      currentPeriodEnd: periodEnd,
      eventTimestamp: new Date(),
      rawPayload: {},
    });

    expect(usersRepo.updateById).toHaveBeenCalledWith('user-2', {
      $set: { plan: 'premium', premiumUntil: periodEnd },
    });
  });
});
