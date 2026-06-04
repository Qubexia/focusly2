import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../src/app.module';
import { buildSwaggerDocument } from '../src/swagger/swagger';

async function main(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false });
  await app.init();
  const doc = buildSwaggerDocument(app);

  for (const path of Object.keys(doc.paths).sort()) {
    if (!path.includes('paymob')) continue;
    const item = doc.paths[path];
    if (!item) continue;
    console.log(path, Object.keys(item).join(', '));
  }

  await app.close();
}

void main();
