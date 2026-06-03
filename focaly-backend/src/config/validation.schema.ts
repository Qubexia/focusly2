import * as Joi from 'joi';

const pemString = (label: string) =>
  Joi.string()
    .custom((value: string, helpers) => {
      const normalized = value.replace(/\\n/g, '\n').trim();
      const beginMarker = `-----BEGIN ${label}-----`;
      const endMarker = `-----END ${label}-----`;

      if (normalized.startsWith(beginMarker) && normalized.endsWith(endMarker)) {
        return value;
      }

      return helpers.error('any.invalid');
    }, `${label} PEM validation`)
    .required();

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().integer().min(1).max(65535).default(3000),
  LOG_LEVEL: Joi.string().valid('fatal', 'error', 'warn', 'info', 'debug', 'trace').default('info'),

  MONGO_URI: Joi.string()
    .uri({ scheme: ['mongodb', 'mongodb+srv'] })
    .required(),
  MONGO_MAX_POOL: Joi.number().integer().min(1).default(50),

  REDIS_URL: Joi.string()
    .uri({ scheme: ['redis', 'rediss'] })
    .required(),
  FOCALY_DISABLE_REDIS: Joi.boolean()
    .truthy('true', '1', 'yes', 'on')
    .falsy('false', '0', 'no', 'off')
    .default(false),

  JWT_PRIVATE_KEY: pemString('PRIVATE KEY'),
  JWT_PUBLIC_KEY: pemString('PUBLIC KEY'),
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
  APP_VERIFY_EMAIL_URL: Joi.string().uri().allow('').optional(),
  APP_OPEN_URL: Joi.string().allow('').optional(),

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

  PAYMOB_API_KEY: Joi.string().allow('').optional(),
  PAYMOB_PUBLIC_KEY: Joi.string().allow('').optional(),
  PAYMOB_SECRET_KEY: Joi.string().allow('').optional(),
  PAYMOB_HMAC_SECRET: Joi.string().allow('').optional(),
  PAYMOB_INTEGRATION_ID: Joi.number().integer().optional(),
  PAYMOB_CURRENCY: Joi.string().default('EGP'),
  PAYMOB_PREMIUM_MONTHLY_AMOUNT_CENTS: Joi.number().integer().min(100).default(9900),
  PAYMOB_PREMIUM_YEARLY_AMOUNT_CENTS: Joi.number().integer().min(100).default(99900),
  PUBLIC_API_BASE_URL: Joi.string().uri().allow('').optional(),
  PAYMOB_APP_SUCCESS_URL: Joi.string().allow('').optional(),
  PAYMOB_APP_FAILURE_URL: Joi.string().allow('').optional(),

  SENTRY_DSN: Joi.string().allow('').optional(),
  OTEL_EXPORTER_OTLP_ENDPOINT: Joi.string().allow('').optional(),

  CORS_ORIGINS: Joi.string().allow('').default(''),

  SWAGGER_USER: Joi.string().allow('').optional(),
  SWAGGER_PASS: Joi.string().allow('').optional(),
});
