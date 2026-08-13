import { Module } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { MongooseModule } from '@nestjs/mongoose';

import { AuditLog, AuditLogSchema } from '../auth/schemas/audit-log.schema';
import { UsersModule } from '../users/users.module';

import { AppleIapService } from './apple-iap.service';
import { GoogleIapService } from './google-iap.service';
import { PaymentEventsRepository } from './payment-events.repository';
import { PaymobController } from './paymob.controller';
import { PaymobService } from './paymob.service';
import { PaymentEvent, PaymentEventSchema } from './schemas/payment-event.schema';
import { Subscription, SubscriptionSchema } from './schemas/subscription.schema';
import { SubscriptionMaintenanceService } from './subscription-maintenance.service';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionsRepository } from './subscriptions.repository';
import { SubscriptionsService } from './subscriptions.service';

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
  controllers: [SubscriptionController, PaymobController],
  providers: [
    SubscriptionsService,
    SubscriptionsRepository,
    PaymentEventsRepository,
    GoogleIapService,
    AppleIapService,
    PaymobService,
    SubscriptionMaintenanceService,
  ],
  exports: [SubscriptionsService, SubscriptionsRepository],
})
export class SubscriptionModule {}
