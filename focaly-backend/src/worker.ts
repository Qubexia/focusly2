import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger as PinoLogger } from 'nestjs-pino';

import { WorkerModule } from './worker.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.createApplicationContext(WorkerModule, { bufferLogs: true });
  app.useLogger(app.get(PinoLogger));
  await app.init();

  const logger = app.get(PinoLogger);
  logger.log('Focaly worker started (BullMQ consumers + cron will register in their feature modules).');
}

void bootstrap();
