import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LoggerModule as PinoLoggerModule } from 'nestjs-pino';
import { randomUUID } from 'crypto';

@Global()
@Module({
  imports: [
    PinoLoggerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        pinoHttp: {
          level: config.get<string>('app.logLevel') ?? 'info',
          genReqId: (req) => (req.headers['x-request-id'] as string) ?? randomUUID(),
          customProps: (req) => ({
            requestId: (req as { id?: string }).id,
            userId: (req as { user?: { id?: string } }).user?.id,
          }),
          redact: {
            paths: [
              'req.headers.authorization',
              'req.headers.cookie',
              '*.password',
              '*.passwordHash',
              '*.refreshToken',
              '*.accessToken',
              '*.idToken',
              '*.purchaseToken',
              '*.receipt',
            ],
            censor: '[REDACTED]',
          },
          transport:
            config.get<string>('app.env') === 'development'
              ? { target: 'pino-pretty', options: { singleLine: true, colorize: true } }
              : undefined,
        },
      }),
    }),
  ],
  exports: [PinoLoggerModule],
})
export class LoggerModule {}
