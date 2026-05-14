import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

import { AppModule } from '../src/app.module';
import { buildSwaggerDocument } from '../src/swagger/swagger';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false });
  const document = buildSwaggerDocument(app);

  const outPath = resolve(__dirname, '../docs/openapi.json');
  writeFileSync(outPath, JSON.stringify(document, null, 2));
  console.log(`OpenAPI document written to ${outPath}`);

  await app.close();
}

void bootstrap();
