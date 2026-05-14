import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { UsersModule } from '../users/users.module';

import { PaymentEventsRepository } from './payment-events.repository';
import { StripeService } from './stripe.service';
import { GoogleIapService } from './google-iap.service';
import { AppleIapService } from './apple-iap.service';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionMaintenanceService } from './subscription-maintenance.service';
import { SubscriptionsRepository } from './subscriptions.repository';
import { SubscriptionsService } from './subscriptions.service';
import { AuditLog, AuditLogSchema } from '../auth/schemas/audit-log.schema';
import { Subscription, SubscriptionSchema } from './schemas/subscription.schema';
import { PaymentEvent, PaymentEventSchema } from './schemas/payment-event.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Subscription.name, schema: SubscriptionSchema },
      { name: PaymentEvent.name, schema: PaymentEventSchema },
      { name: AuditLog.name, schema: AuditLogSchema },
    ]),
    CqrsModule,
    UsersModule,
  ],
  controllers: [SubscriptionController],
  providers: [
    SubscriptionsService,
    SubscriptionsRepository,
    PaymentEventsRepository,
    StripeService,
    GoogleIapService,
    AppleIapService,
    SubscriptionMaintenanceService,
  ],
  exports: [SubscriptionsService, SubscriptionsRepository],
})
export class SubscriptionModule {}
