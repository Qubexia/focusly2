import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerCustomOptions, SwaggerModule } from '@nestjs/swagger';

import { ERROR_CODES, ErrorResponse } from '../common/dto/api-response';

export function buildSwaggerDocument(app: INestApplication) {
  const swagger = new DocumentBuilder()
    .setTitle('Focaly API')
    .setDescription('Focaly Study Management Mobile App backend')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: '15-minute access credential',
      },
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

  return document;
}

export const swaggerUiOptions: SwaggerCustomOptions = {
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
    filter: true,
    tryItOutEnabled: true,
    docExpansion: 'none',
  },
};
