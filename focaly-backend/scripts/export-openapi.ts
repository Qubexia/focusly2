import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

import { AppModule } from '../src/app.module';
import { ErrorResponse } from '../src/common/dto/api-response';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false });

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
    .build();

  const document = SwaggerModule.createDocument(app, swagger, {
    extraModels: [ErrorResponse],
  });

  const outPath = resolve(__dirname, '../docs/openapi.json');
  writeFileSync(outPath, JSON.stringify(document, null, 2));
  console.log(`OpenAPI document written to ${outPath}`);

  await app.close();
}

void bootstrap();
