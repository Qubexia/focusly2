import { Injectable, Logger } from '@nestjs/common';

export interface AppleIapVerificationResult {
  valid: boolean;
  userId?: string;
  productId?: string;
  transactionId?: string;
  expiryDate?: Date;
}

@Injectable()
export class AppleIapService {
  private readonly logger = new Logger(AppleIapService.name);

  async verifyReceipt(_receiptData: string): Promise<AppleIapVerificationResult> {
    this.logger.warn('AppleIapService.verifyReceipt not fully implemented');
    return { valid: true, expiryDate: new Date(Date.now() + 30 * 24 * 3600_000) };
  }
}
