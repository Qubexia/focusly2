import { registerAs } from '@nestjs/config';

export default registerAs('db', () => ({
  uri: process.env.MONGO_URI ?? '',
  options: {
    maxPoolSize: Number(process.env.MONGO_MAX_POOL ?? 50),
    autoIndex: process.env.NODE_ENV !== 'production',
  },
}));
