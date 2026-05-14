import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

@Injectable()
export class AuditLogMiddleware implements NestMiddleware {
  private readonly logger = new Logger('Audit');

  use(req: Request, res: Response, next: NextFunction): void {
    res.on('finish', () => {
      if (this.shouldAudit(req)) {
        this.logger.log({
          requestId: (req as { id?: string }).id,
          method: req.method,
          path: req.url,
          status: res.statusCode,
          userId: (req as { user?: { id?: string } }).user?.id,
        });
      }
    });
    next();
  }

  private shouldAudit(req: Request): boolean {
    const url = req.url;
    return (
      url.startsWith('/v1/auth/') ||
      url.startsWith('/v1/subscription/') ||
      url.startsWith('/v1/users/me')
    );
  }
}
