export const FCM_CLIENT = Symbol('FCM_CLIENT');

export interface FcmMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface FcmSendResult {
  successCount: number;
  failureTokens: Array<{ token: string; permanent: boolean; reason: string }>;
}

export interface FcmClient {
  send(messages: FcmMessage[]): Promise<FcmSendResult>;
}
