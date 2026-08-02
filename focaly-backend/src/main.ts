import 'reflect-metadata';
import { ClassSerializerInterceptor, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory, Reflector } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { SwaggerModule } from '@nestjs/swagger';
import compression from 'compression';
import basicAuth from 'express-basic-auth';
import helmet from 'helmet';
import { Logger as PinoLogger } from 'nestjs-pino';

import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { buildSwaggerDocument, swaggerUiOptions } from './swagger/swagger';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { bufferLogs: true });

  app.useLogger(app.get(PinoLogger));

  const config = app.get(ConfigService);
  const env = config.get<string>('app.env');
  const port = config.get<number>('app.port') ?? 3000;
  const corsOrigins = config.get<string[]>('app.corsOrigins') ?? [];

  const isProduction = env === 'production';

  // Behind exactly one reverse proxy (nginx). Without this, Express cannot tell
  // a real client IP from a forged X-Forwarded-For, which is what the throttler
  // keys its buckets on.
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(compression());

  if (isProduction && corsOrigins.length === 0) {
    throw new Error('CORS_ORIGINS must list at least one origin in production.');
  }

  app.enableCors({
    // Never reflect an arbitrary origin while allowing credentials.
    origin: corsOrigins.length > 0 ? corsOrigins : !isProduction,
    credentials: true,
  });

  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new ClassSerializerInterceptor(app.get(Reflector)),
    new TransformInterceptor(),
  );

  // In production the docs are mounted only when credentials exist, so a deploy
  // that forgets SWAGGER_USER/SWAGGER_PASS hides the API surface instead of
  // publishing it.
  const swaggerUser = config.get<string>('app.swagger.user');
  const swaggerPass = config.get<string>('app.swagger.pass');
  const swaggerEnabled = !isProduction || Boolean(swaggerUser && swaggerPass);

  if (swaggerEnabled) {
    if (isProduction) {
      app.use(
        ['/docs', '/docs-json'],
        basicAuth({ users: { [swaggerUser!]: swaggerPass! }, challenge: true }),
      );
    }

    const document = buildSwaggerDocument(app);
    SwaggerModule.setup('docs', app, document, swaggerUiOptions);
  }

  await app.listen(port, '0.0.0.0');
  const logger = app.get(PinoLogger);
  const url = await app.getUrl();
  logger.log(`Application is running on: ${url}`);
  logger.log(
    swaggerEnabled
      ? `Swagger documentation: ${url}/docs`
      : 'Swagger documentation disabled (set SWAGGER_USER and SWAGGER_PASS to enable).',
  );
}

void bootstrap();
