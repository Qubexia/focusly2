import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import type { Request } from 'express';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = ctx.switchToHttp();
    const req = http.getRequest<Request>();
    const started = Date.now();
    const requestId = (req as { id?: string }).id;

    return next.handle().pipe(
      tap({
        next: () =>
          this.logger.log(
            `${req.method} ${req.url} ${Date.now() - started}ms requestId=${requestId ?? '-'}`,
          ),
        error: (err: unknown) =>
          this.logger.warn(
            `${req.method} ${req.url} ERR ${Date.now() - started}ms requestId=${requestId ?? '-'} ${
              (err as Error)?.message ?? ''
            }`,
          ),
      }),
    );
  }
}
