import appConfig from './env/app.config';
import dbConfig from './env/db.config';
import fcmConfig from './env/fcm.config';
import jwtConfig from './env/jwt.config';
import mailerConfig from './env/mailer.config';
import openaiConfig from './env/openai.config';
import redisConfig from './env/redis.config';
import s3Config from './env/s3.config';
import stripeConfig from './env/stripe.config';

export const configLoaders = [
  appConfig,
  dbConfig,
  redisConfig,
  jwtConfig,
  fcmConfig,
  openaiConfig,
  stripeConfig,
  s3Config,
  mailerConfig,
];
