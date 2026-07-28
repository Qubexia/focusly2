import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { EmailVerifiedGuard } from '../../common/guards/email-verified.guard';

import { AppleIapService } from './apple-iap.service';
import { AppleIapVerifyDto } from './dto/apple-iap-verify.dto';
import { GoogleIapVerifyDto } from './dto/google-iap-verify.dto';
import { GoogleIapService } from './google-iap.service';
import { SubscriptionsService } from './subscriptions.service';

@ApiTags('Subscription')
@Controller({ path: 'subscription', version: '1' })
export class SubscriptionController {
  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly googleIapService: GoogleIapService,
    private readonly appleIapService: AppleIapService,
  ) {}

  @Get('me')
  async getMySubscription(@CurrentUser() user: CurrentUserPayload) {
    return this.subscriptionsService.getSubscription(user.id);
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
