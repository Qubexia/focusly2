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

import { AppleIapVerifyDto } from './dto/apple-iap-verify.dto';
import { GoogleIapVerifyDto } from './dto/google-iap-verify.dto';
import { StripeCheckoutDto } from './dto/stripe-checkout.dto';
import { StripePortalDto } from './dto/stripe-portal.dto';
import { StripeService } from './stripe.service';
import { SubscriptionsService } from './subscriptions.service';

@ApiTags('Subscription')
@Controller({ path: 'subscription', version: '1' })
export class SubscriptionController {
  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly stripeService: StripeService,
  ) {}

  @Get('me')
  async getMySubscription(@CurrentUser() user: CurrentUserPayload) {
    return this.subscriptionsService.getSubscription(user.id);
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('stripe/checkout')
  async createCheckout(
    @CurrentUser() user: CurrentUserPayload,
    @Body() _dto: StripeCheckoutDto,
  ) {
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
    const event = this.stripeService.constructWebhookEvent(
      (req as any).rawBody as Buffer,
      signature,
    );

    const session = event.data.object as Record<string, any>;

    await this.subscriptionsService.applyEvent({
      provider: 'stripe',
      eventId: event.id,
      providerSubId: (session.subscription as string) ?? event.id,
      userId: session.metadata?.userId ?? '',
      status: event.type === 'checkout.session.completed' ? 'active' : 'canceled',
      currentPeriodEnd: session.current_period_end
        ? new Date(session.current_period_end * 1000)
        : null,
      eventTimestamp: new Date((event.created ?? 0) * 1000),
      rawPayload: event as any,
    });

    return { received: true };
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('iap/google/verify')
  async verifyGooglePurchase(
    @CurrentUser() user: CurrentUserPayload,
    @Body() _dto: GoogleIapVerifyDto,
  ) {
    return { outcome: 'applied' };
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('iap/apple/verify')
  async verifyApplePurchase(
    @CurrentUser() user: CurrentUserPayload,
    @Body() _dto: AppleIapVerifyDto,
  ) {
    return { outcome: 'applied' };
  }

  @Post('cancel')
  @HttpCode(HttpStatus.NO_CONTENT)
  async cancelSubscription(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.subscriptionsService.applyEvent({
      provider: 'stripe',
      eventId: `manual-cancel-${user.id}-${Date.now()}`,
      providerSubId: `manual-${user.id}`,
      userId: user.id,
      status: 'canceled',
      currentPeriodEnd: null,
      eventTimestamp: new Date(),
      rawPayload: {},
    });
  }
}
