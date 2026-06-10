import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Post,
  RawBodyRequest,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { EmailVerifiedGuard } from '../../common/guards/email-verified.guard';

import { AppleIapService } from './apple-iap.service';
import { AppleIapVerifyDto } from './dto/apple-iap-verify.dto';
import { GoogleIapVerifyDto } from './dto/google-iap-verify.dto';
import { StripeCheckoutDto } from './dto/stripe-checkout.dto';
import { StripePortalDto } from './dto/stripe-portal.dto';
import { GoogleIapService } from './google-iap.service';
import { StripeService } from './stripe.service';
import { SubscriptionsService } from './subscriptions.service';

interface StripeCheckoutSessionObject {
  subscription?: string;
  metadata?: { userId?: string };
  current_period_end?: number;
}

@ApiTags('Subscription')
@Controller({ path: 'subscription', version: '1' })
export class SubscriptionController {
  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly stripeService: StripeService,
    private readonly googleIapService: GoogleIapService,
    private readonly appleIapService: AppleIapService,
  ) {}

  @Get('me')
  async getMySubscription(@CurrentUser() user: CurrentUserPayload) {
    return this.subscriptionsService.getSubscription(user.id);
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('stripe/checkout')
  async createCheckout(@CurrentUser() user: CurrentUserPayload, @Body() _dto: StripeCheckoutDto) {
    return this.stripeService.createCheckoutSession(user.id);
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('stripe/portal')
  async createPortal(@Body() dto: StripePortalDto) {
    return this.stripeService.createPortalSession(dto.customerId);
  }

  @Public()
  @Post('webhook/stripe')
  @HttpCode(HttpStatus.OK)
  async handleStripeWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    const rawBody = req.rawBody;
    if (!rawBody) {
      throw new Error('Missing Stripe webhook raw body');
    }

    const event = this.stripeService.constructWebhookEvent(rawBody, signature);

    const session = event.data.object as StripeCheckoutSessionObject;

    await this.subscriptionsService.applyEvent({
      provider: 'stripe',
      eventId: event.id,
      providerSubId: session.subscription ?? event.id,
      userId: session.metadata?.userId ?? '',
      status: event.type === 'checkout.session.completed' ? 'active' : 'canceled',
      currentPeriodEnd: session.current_period_end
        ? new Date(session.current_period_end * 1000)
        : null,
      eventTimestamp: new Date((event.created ?? 0) * 1000),
      rawPayload: { type: event.type, id: event.id },
    });

    return { received: true };
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('iap/google/verify')
  async verifyGooglePurchase(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: GoogleIapVerifyDto,
  ) {
    const verification = await this.googleIapService.verifyPurchase(
      dto.packageName,
      dto.productId,
      dto.purchaseToken,
    );

    if (!verification.valid) {
      return { outcome: 'rejected' };
    }

    return this.subscriptionsService.applyEvent({
      provider: 'google_play',
      eventId: `google-${dto.purchaseToken}`,
      providerSubId: dto.purchaseToken,
      userId: user.id,
      status: 'active',
      currentPeriodEnd: verification.expiryDate ?? null,
      priceId: dto.productId,
      eventTimestamp: new Date(),
      rawPayload: { packageName: dto.packageName, productId: dto.productId },
    });
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('iap/apple/verify')
  async verifyApplePurchase(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: AppleIapVerifyDto,
  ) {
    const verification = await this.appleIapService.verifyReceipt(dto.receiptData);

    if (!verification.valid) {
      return { outcome: 'rejected' };
    }

    const providerSubId = verification.transactionId ?? `apple-${user.id}-${Date.now()}`;

    return this.subscriptionsService.applyEvent({
      provider: 'app_store',
      eventId: providerSubId,
      providerSubId,
      userId: user.id,
      status: 'active',
      currentPeriodEnd: verification.expiryDate ?? null,
      priceId: verification.productId ?? null,
      eventTimestamp: new Date(),
      rawPayload: { receiptLength: dto.receiptData.length },
    });
  }

  @Post('cancel')
  async cancelSubscription(@CurrentUser() user: CurrentUserPayload) {
    return this.subscriptionsService.cancelSubscription(user.id);
  }
}
