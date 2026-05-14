import { registerAs } from '@nestjs/config';

export default registerAs('fcm', () => ({
  serviceAccountJson: process.env.FCM_SERVICE_ACCOUNT_JSON ?? '',
}));
