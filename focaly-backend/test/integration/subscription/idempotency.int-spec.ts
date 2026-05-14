import { CqrsModule, EventBus } from '@nestjs/cqrs';
import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';

import { PaymentEventsRepository } from '../../../src/modules/subscription/payment-events.repository';
import { PaymentEvent, PaymentEventSchema } from '../../../src/modules/subscription/schemas/payment-event.schema';
import { Subscription, SubscriptionSchema } from '../../../src/modules/subscription/schemas/subscription.schema';
import { SubscriptionsRepository } from '../../../src/modules/subscription/subscriptions.repository';
import { SubscriptionsService } from '../../../src/modules/subscription/subscriptions.service';
import { User, UserSchema } from '../../../src/modules/users/schemas/user.schema';
import { UsersRepository } from '../../../src/modules/users/users.repository';

describe('Stripe webhook idempotency (integration)', () => {
  let mongod: MongoMemoryServer;
  let userModel: Model<User>;
  let paymentEventModel: Model<PaymentEvent>;
  let subscriptionModel: Model<Subscription>;
  let service: SubscriptionsService;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    userModel = mongoose.model(User.name, UserSchema);
    paymentEventModel = mongoose.model(PaymentEvent.name, PaymentEventSchema);
    subscriptionModel = mongoose.model(Subscription.name, SubscriptionSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await userModel.deleteMany({});
    await paymentEventModel.deleteMany({});
    await subscriptionModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [
        SubscriptionsService,
        SubscriptionsRepository,
        PaymentEventsRepository,
        UsersRepository,
        { provide: getModelToken(Subscription.name), useValue: subscriptionModel },
        { provide: getModelToken(PaymentEvent.name), useValue: paymentEventModel },
        { provide: getModelToken(User.name), useValue: userModel },
      ],
    }).compile();

    service = module.get(SubscriptionsService);
  });

  it('same event delivered twice → second call returns noop', async () => {
    const user = await userModel.create({
      email: 'test@test.com',
      name: 'Test',
      settings: {},
      plan: 'free',
    });

    const eventPayload = {
      provider: 'stripe' as const,
      eventId: 'evt_123',
      providerSubId: 'sub_abc',
      userId: user.id,
      status: 'active' as const,
      currentPeriodEnd: new Date(Date.now() + 30 * 86400_000),
      eventTimestamp: new Date(),
      rawPayload: { id: 'evt_123' },
    };

    const first = await service.applyEvent(eventPayload);
    expect(first.outcome).toBe('applied');

    const second = await service.applyEvent(eventPayload);
    expect(second.outcome).toBe('noop');

    const updatedUser = await userModel.findById(user.id).exec();
    expect(updatedUser!.plan).toBe('premium');
  });
});
