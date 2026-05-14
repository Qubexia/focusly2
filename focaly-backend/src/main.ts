import 'reflect-metadata';
import {
  ClassSerializerInterceptor,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory, Reflector } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import compression from 'compression';
import basicAuth from 'express-basic-auth';
import helmet from 'helmet';
import { Logger as PinoLogger } from 'nestjs-pino';

import { AppModule } from './app.module';
import { ERROR_CODES, ErrorResponse } from './common/dto/api-response';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { MongoExceptionFilter } from './common/filters/mongo-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.useLogger(app.get(PinoLogger));

  const config = app.get(ConfigService);
  const env = config.get<string>('app.env');
  const port = config.get<number>('app.port') ?? 3000;
  const corsOrigins = config.get<string[]>('app.corsOrigins') ?? [];

  app.use(helmet());
  app.use(compression());

  app.enableCors({
    origin: corsOrigins.length > 0 ? corsOrigins : true,
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
  app.useGlobalFilters(new AllExceptionsFilter(), new MongoExceptionFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new TransformInterceptor(),
    new ClassSerializerInterceptor(app.get(Reflector)),
  );

  if (env === 'production') {
    const user = config.get<string>('app.swagger.user');
    const pass = config.get<string>('app.swagger.pass');
    if (user && pass) {
      app.use(
        ['/docs', '/docs-json'],
        basicAuth({ users: { [user]: pass }, challenge: true }),
      );
    }
  }

  const swagger = new DocumentBuilder()
    .setTitle('Focaly API')
    .setDescription('Focaly Study Management Mobile App — backend')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', description: '15-min access credential' },
      'bearerAccess',
    )
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: '30-day rotating refresh credential',
      },
      'bearerRefresh',
    )
    .addSecurityRequirements('bearerAccess')
    .addTag('Health')
    .build();

  const document = SwaggerModule.createDocument(app, swagger, {
    extraModels: [ErrorResponse],
  });
  for (const code of Object.values(ERROR_CODES)) {
    void code;
  }

  SwaggerModule.setup('docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
      filter: true,
      tryItOutEnabled: true,
      docExpansion: 'none',
    },
  });

  await app.listen(port);
}

void bootstrap();
