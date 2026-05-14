import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus } from '@nestjs/common';
import type { Response } from 'express';

import { ERROR_CODES, ErrorResponse } from '../dto/api-response';

interface MongoLikeError extends Error {
  name: string;
  code?: number;
  keyValue?: unknown;
}

function isMongoServerError(value: unknown): value is MongoLikeError {
  return (
    typeof value === 'object' &&
    value !== null &&
    (value as { name?: string }).name === 'MongoServerError'
  );
}

@Catch()
export class MongoExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    if (!isMongoServerError(exception)) {
      throw exception;
    }
    const res = host.switchToHttp().getResponse<Response>();

    if (exception.code === 11000) {
      const body: ErrorResponse = {
        code: ERROR_CODES.DUPLICATE_KEY,
        message: 'Duplicate key',
        details: { keyValue: exception.keyValue },
      };
      res.status(HttpStatus.CONFLICT).json(body);
      return;
    }

    const body: ErrorResponse = {
      code: ERROR_CODES.INTERNAL,
      message: 'Database error',
    };
    res.status(HttpStatus.INTERNAL_SERVER_ERROR).json(body);
  }
}
