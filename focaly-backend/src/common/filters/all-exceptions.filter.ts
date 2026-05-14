import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';

import { ERROR_CODES, ErrorResponse } from '../dto/api-response';

interface MongoLikeError extends Error {
  code?: number;
  keyValue?: unknown;
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    const { status, body } = this.normalize(exception);

    if (status >= 500) {
      this.logger.error(
        { err: exception, path: req.url, method: req.method },
        'Unhandled exception',
      );
    }

    res.status(status).json(body);
  }

  private normalize(exception: unknown): { status: number; body: ErrorResponse } {
    if (this.isMongoDuplicateKeyError(exception)) {
      return {
        status: HttpStatus.CONFLICT,
        body: {
          code: ERROR_CODES.DUPLICATE_KEY,
          message: 'Duplicate key',
          details: { keyValue: (exception as MongoLikeError).keyValue },
        },
      };
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const payload = exception.getResponse();

      if (typeof payload === 'object' && payload !== null) {
        const obj = payload as Record<string, unknown>;
        const code = typeof obj.code === 'string' ? obj.code : this.codeForStatus(status);
        const message = typeof obj.message === 'string'
          ? obj.message
          : Array.isArray(obj.message)
            ? (obj.message as string[]).join('; ')
            : exception.message;
        const details =
          typeof obj.details === 'object' && obj.details !== null
            ? (obj.details as Record<string, unknown>)
            : undefined;
        return { status, body: { code, message, details } };
      }

      return {
        status,
        body: { code: this.codeForStatus(status), message: String(payload) },
      };
    }

    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      body: { code: ERROR_CODES.INTERNAL, message: 'Internal server error' },
    };
  }

  private codeForStatus(status: number): string {
    switch (status) {
      case 400:
      case 422:
        return ERROR_CODES.VALIDATION;
      case 401:
        return ERROR_CODES.UNAUTHORIZED;
      case 403:
        return ERROR_CODES.FORBIDDEN;
      case 404:
        return ERROR_CODES.NOT_FOUND;
      case 409:
        return ERROR_CODES.CONFLICT;
      case 429:
        return ERROR_CODES.RATE_LIMIT;
      default:
        return ERROR_CODES.INTERNAL;
    }
  }

  private isMongoDuplicateKeyError(exception: unknown): exception is MongoLikeError {
    return (
      typeof exception === 'object' &&
      exception !== null &&
      (exception as MongoLikeError).name === 'MongoServerError' &&
      (exception as MongoLikeError).code === 11000
    );
  }
}
