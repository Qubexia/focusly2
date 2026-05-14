import { Injectable, Logger } from '@nestjs/common';

export interface GoogleIapVerificationResult {
  valid: boolean;
  userId?: string;
  productId?: string;
  purchaseToken?: string;
  expiryDate?: Date;
}

@Injectable()
export class GoogleIapService {
  private readonly logger = new Logger(GoogleIapService.name);

  async verifyPurchase(
    _packageName: string,
    _productId: string,
    _purchaseToken: string,
  ): Promise<GoogleIapVerificationResult> {
    this.logger.warn('GoogleIapService.verifyPurchase not fully implemented');
    return { valid: true, expiryDate: new Date(Date.now() + 30 * 24 * 3600_000) };
  }
}
