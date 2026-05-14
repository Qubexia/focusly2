import { Injectable, Logger } from '@nestjs/common';

import { FcmClient, FcmMessage, FcmSendResult } from './fcm.tokens';

@Injectable()
export class FcmFakeClient implements FcmClient {
  private readonly logger = new Logger(FcmFakeClient.name);

  async send(messages: FcmMessage[]): Promise<FcmSendResult> {
    for (const msg of messages) {
      this.logger.log(
        `[fake-push] token=${msg.token.slice(0, 8)}… title=${JSON.stringify(msg.title)}`,
      );
    }
    return { successCount: messages.length, failureTokens: [] };
  }
}
