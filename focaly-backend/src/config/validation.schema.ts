import * as Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().integer().min(1).max(65535).default(3000),
  LOG_LEVEL: Joi.string()
    .valid('fatal', 'error', 'warn', 'info', 'debug', 'trace')
    .default('info'),

  MONGO_URI: Joi.string().uri({ scheme: ['mongodb', 'mongodb+srv'] }).required(),
  MONGO_MAX_POOL: Joi.number().integer().min(1).default(50),

  REDIS_URL: Joi.string().uri({ scheme: ['redis', 'rediss'] }).required(),

  JWT_PRIVATE_KEY: Joi.string().required(),
  JWT_PUBLIC_KEY: Joi.string().required(),
  JWT_ACCESS_TTL: Joi.number().integer().min(60).default(900),
  JWT_REFRESH_TTL: Joi.number().integer().min(3600).default(2_592_000),
  EMAIL_TOKEN_SECRET: Joi.string().min(16).required(),

  GOOGLE_CLIENT_ID: Joi.string().allow('').optional(),

  MAIL_PROVIDER: Joi.string().valid('ethereal', 'smtp', 'ses').default('ethereal'),
  MAIL_FROM: Joi.string().default('Focaly <noreply@focaly.app>'),
  SMTP_HOST: Joi.string().allow('').optional(),
  SMTP_PORT: Joi.number().integer().min(1).max(65535).allow('').optional(),
  SMTP_USER: Joi.string().allow('').optional(),
  SMTP_PASS: Joi.string().allow('').optional(),

  S3_BUCKET: Joi.string().required(),
  S3_REGION: Joi.string().default('us-east-1'),
  S3_ENDPOINT: Joi.string().allow('').optional(),
  AWS_ACCESS_KEY_ID: Joi.string().allow('').optional(),
  AWS_SECRET_ACCESS_KEY: Joi.string().allow('').optional(),

  FCM_SERVICE_ACCOUNT_JSON: Joi.string().allow('').optional(),

  OPENAI_API_KEY: Joi.string().allow('').optional(),
  AWS_TEXTRACT_REGION: Joi.string().allow('').optional(),

  STRIPE_SECRET_KEY: Joi.string().allow('').optional(),
  STRIPE_WEBHOOK_SECRET: Joi.string().allow('').optional(),

  SENTRY_DSN: Joi.string().allow('').optional(),
  OTEL_EXPORTER_OTLP_ENDPOINT: Joi.string().allow('').optional(),

  CORS_ORIGINS: Joi.string().allow('').default(''),

  SWAGGER_USER: Joi.string().allow('').optional(),
  SWAGGER_PASS: Joi.string().allow('').optional(),
});
