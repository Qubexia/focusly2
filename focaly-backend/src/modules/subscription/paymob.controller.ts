import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Logger,
  Param,
  Post,
  Query,
  Req,
  Res,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Request, Response } from 'express';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { EmailVerifiedGuard } from '../../common/guards/email-verified.guard';
import { RolesGuard } from '../../common/guards/roles.guard';

import { PaymobCardPayDto } from './dto/paymob-card-pay.dto';
import { PaymobCheckoutDto } from './dto/paymob-checkout.dto';
import { PaymobConfirmSdkDto } from './dto/paymob-confirm-sdk.dto';
import {
  parseUserIdFromSpecialReference,
  verifyResponseCallbackHmac,
  verifyTransactionProcessedHmac,
} from './paymob-hmac.util';
import { PaymobService } from './paymob.service';
import { SubscriptionsService } from './subscriptions.service';

@ApiTags('Subscription — Paymob')
@Controller({ path: 'subscription/paymob', version: '1' })
export class PaymobController {
  private readonly logger = new Logger(PaymobController.name);

  constructor(
    private readonly paymobService: PaymobService,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  /** URLs to paste in Paymob dashboard (admin-only: leaks integration metadata). */
  @Roles('admin')
  @UseGuards(RolesGuard)
  @Get('config-urls')
  getConfigUrls() {
    return {
      transactionProcessedCallback: this.paymobService.webhookUrl,
      transactionResponseCallback: this.paymobService.redirectUrl,
      checkoutRequirements: {
        unifiedCheckout:
          'Needs an Online Card (MIGS) integration ID — works with Intention API + Unified Checkout.',
        legacyIframe:
          'VPC/wallet integrations need PAYMOB_IFRAME_ID from Developers → iFrames in Accept Dashboard.',
        currentIntegrationId: Number(process.env.PAYMOB_INTEGRATION_ID ?? 0),
        iframeIdConfigured: Number(process.env.PAYMOB_IFRAME_ID ?? 0) > 0,
      },
      note:
        'Use a public HTTPS URL in production (e.g. ngrok for local dev). ' +
        'Processed callback = server webhook (POST). Response callback = user redirect (GET). ' +
        'Replace the default post_pay URLs on your Paymob integration with the two URLs above.',
    };
  }

  @UseGuards(EmailVerifiedGuard)
  @Post('checkout')
  async createCheckout(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: PaymobCheckoutDto,
    @Req() req: Request,
  ) {
    const proto =
      (typeof req.headers['x-forwarded-proto'] === 'string'
        ? req.headers['x-forwarded-proto']
        : undefined) ??
      req.protocol ??
      'http';
    const requestOrigin = req.headers.host ? `${proto}://${req.headers.host}` : undefined;

    return this.paymobService.createPremiumCheckout(
      user.id,
      dto.plan,
      dto.checkoutBaseUrl,
      requestOrigin,
    );
  }

  /** Activate premium immediately after a successful native Paymob SDK payment. */
  @UseGuards(EmailVerifiedGuard)
  @Post('confirm-sdk')
  async confirmSdkPayment(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: PaymobConfirmSdkDto,
  ) {
    // Never grant premium on the client's word alone — Paymob is asked whether
    // this transaction really succeeded, for this user, at this plan's price.
    const verified = await this.paymobService.verifySdkTransaction(
      user.id,
      dto.plan,
      dto.transactionId,
    );

    return this.subscriptionsService.activatePaymobFromSdk(
      user.id,
      verified.plan,
      verified.transactionId,
    );
  }

  /** Hosted card checkout page (replaces broken Paymob /standalone/ SPA on mobile). */
  @Public()
  @Get('open/:sessionId/checkout.js')
  @Header('Content-Type', 'application/javascript; charset=utf-8')
  hostedCheckoutScript(@Param('sessionId') sessionId: string): string {
    return this.paymobService.renderHostedCheckoutScript(sessionId);
  }

  @Public()
  @Get('open/:sessionId')
  @Header('Content-Type', 'text/html; charset=utf-8')
  openHostedCheckout(@Param('sessionId') sessionId: string): string {
    return this.paymobService.renderHostedCheckoutPage(sessionId);
  }

  @Public()
  @Post('open/:sessionId/pay')
  async payHostedCheckout(@Param('sessionId') sessionId: string, @Body() dto: PaymobCardPayDto) {
    return this.paymobService.processHostedCardPayment(sessionId, dto);
  }

  /**
   * Transaction Processed Callback (webhook) — configure in Paymob integration settings.
   */
  @Public()
  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  async handleWebhook(@Req() req: Request, @Query('hmac') queryHmac?: string) {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const transaction = (body.obj ?? body) as Record<string, unknown>;
    const receivedHmac =
      queryHmac ?? (body.hmac as string | undefined) ?? (req.headers['hmac'] as string | undefined);

    // Fail closed: an unsigned or badly-signed callback is never processed.
    // Skipping verification when the signature is absent would let anyone mint
    // premium for any account by POSTing a forged transaction.
    const hmacSecret = this.paymobService.callbackHmacSecret;
    if (!hmacSecret) {
      this.logger.error('Rejected Paymob webhook: PAYMOB_HMAC_SECRET is not configured.');
      throw new UnauthorizedException({ message: 'Webhook verification is not configured.' });
    }
    if (!receivedHmac || !verifyTransactionProcessedHmac(transaction, receivedHmac, hmacSecret)) {
      this.logger.warn('Rejected Paymob webhook: missing or invalid HMAC signature.');
      throw new UnauthorizedException({ message: 'Invalid webhook signature.' });
    }

    const success = transaction.success === true || transaction.success === 'true';
    const pending = transaction.pending === true || transaction.pending === 'true';
    const refunded = transaction.is_refunded === true || transaction.is_refunded === 'true';
    const voided = transaction.is_voided === true || transaction.is_voided === 'true';
    if (!success || pending || refunded || voided) {
      return { received: true, outcome: 'ignored', reason: 'not_successful' };
    }

    const order = transaction.order as Record<string, unknown> | undefined;
    const specialReference =
      (order?.merchant_order_id as string | undefined) ??
      (transaction.special_reference as string | undefined) ??
      (body.special_reference as string | undefined);

    const extras =
      (transaction.extras as Record<string, unknown> | undefined) ??
      (body.extras as Record<string, unknown> | undefined);
    const userId =
      parseUserIdFromSpecialReference(specialReference) ??
      (typeof extras?.userId === 'string' ? extras.userId : null);
    if (!userId) {
      return { received: true, outcome: 'ignored', reason: 'unknown_user_reference' };
    }

    const rawId = transaction.id;
    const transactionId =
      typeof rawId === 'string' || typeof rawId === 'number'
        ? String(rawId)
        : `paymob-${Date.now()}`;
    // Entitlement follows the amount actually paid, not the client-declared
    // plan: a monthly payment tagged `extras.plan = yearly` must not buy a year.
    const paidCurrency =
      typeof transaction.currency === 'string' ? transaction.currency.toUpperCase() : '';
    if (paidCurrency && paidCurrency !== this.paymobService.currency) {
      this.logger.warn(`Ignored Paymob webhook: unexpected currency ${paidCurrency}.`);
      return { received: true, outcome: 'ignored', reason: 'currency_mismatch' };
    }

    const plan = this.paymobService.resolvePlanFromAmount(transaction.amount_cents);
    if (!plan) {
      this.logger.warn(
        `Ignored Paymob webhook: amount ${JSON.stringify(transaction.amount_cents)} matches no plan price.`,
      );
      return { received: true, outcome: 'ignored', reason: 'amount_mismatch' };
    }

    const periodEnd = new Date();
    if (plan === 'yearly') {
      periodEnd.setFullYear(periodEnd.getFullYear() + 1);
    } else {
      periodEnd.setMonth(periodEnd.getMonth() + 1);
    }

    const result = await this.subscriptionsService.applyEvent({
      provider: 'paymob',
      eventId: `paymob-tx-${transactionId}`,
      providerSubId: transactionId,
      userId,
      status: 'active',
      currentPeriodEnd: periodEnd,
      priceId: specialReference,
      eventTimestamp: new Date(),
      rawPayload: body,
    });

    return { received: true, outcome: result.outcome };
  }

  /**
   * Transaction Response Callback (redirect) — user lands here after payment.
   */
  @Public()
  @Get('redirect')
  handleRedirect(@Query() query: Record<string, string>, @Res() res: Response) {
    const hmacSecret = this.paymobService.callbackHmacSecret;
    const receivedHmac = query.hmac;
    if (
      !hmacSecret ||
      !receivedHmac ||
      !verifyResponseCallbackHmac(query, receivedHmac, hmacSecret)
    ) {
      res.status(400).send(this.renderHtml(false, 'Payment verification failed.'));
      return;
    }

    const success = query.success === 'true';
    const appUrl = success
      ? (process.env.PAYMOB_APP_SUCCESS_URL ?? 'zakerly://payment/success')
      : (process.env.PAYMOB_APP_FAILURE_URL ?? 'zakerly://payment/failure');

    res.send(this.renderHtml(success, success ? 'Payment successful' : 'Payment failed', appUrl));
  }

  private renderHtml(success: boolean, message: string, deepLink?: string): string {
    const color = success ? '#00B894' : '#E17055';
    const linkBlock = deepLink
      ? `<p><a href="${deepLink}" style="color:#6C5CE7;font-weight:bold;">Return to Zakerly app</a></p>`
      : '<p>You can close this page and return to the app, then tap Refresh on Premium.</p>';

    return `<!DOCTYPE html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Zakerly Payment</title></head><body style="font-family:system-ui,sans-serif;text-align:center;padding:48px 24px;"><h1 style="color:${color}">${message}</h1>${linkBlock}</body></html>`;
  }
}
