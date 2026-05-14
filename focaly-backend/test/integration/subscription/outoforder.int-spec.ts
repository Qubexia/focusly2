import { CqrsModule } from '@nestjs/cqrs';
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

describe('Out-of-order webhook handling', () => {
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

  it('older cancellation after newer active event is ignored', async () => {
    const user = await userModel.create({
      email: 'test@test.com',
      name: 'Test',
      settings: {},
      plan: 'free',
    });

    const laterEvent = new Date('2026-06-15');
    const earlierEvent = new Date('2026-06-10');

    await service.applyEvent({
      provider: 'stripe',
      eventId: 'evt_active_later',
      providerSubId: 'sub_xyz',
      userId: user.id,
      status: 'active',
      currentPeriodEnd: new Date('2026-07-15'),
      eventTimestamp: laterEvent,
      rawPayload: {},
    });

    const result = await service.applyEvent({
      provider: 'stripe',
      eventId: 'evt_cancel_earlier',
      providerSubId: 'sub_xyz',
      userId: user.id,
      status: 'canceled',
      eventTimestamp: earlierEvent,
      rawPayload: {},
    });

    expect(result.outcome).toBe('noop');

    const updatedUser = await userModel.findById(user.id).exec();
    expect(updatedUser!.plan).toBe('premium');
  });
});
