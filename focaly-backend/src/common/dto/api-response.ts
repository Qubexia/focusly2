import { ApiProperty } from '@nestjs/swagger';

export class ErrorResponse {
  @ApiProperty({ example: 'VALIDATION', description: 'Stable machine-readable error code' })
  code!: string;

  @ApiProperty({ example: 'name must not be empty' })
  message!: string;

  @ApiProperty({ required: false, type: 'object', additionalProperties: true })
  details?: Record<string, unknown>;
}

export const ERROR_CODES = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION: 'VALIDATION',
  CONFLICT: 'CONFLICT',
  DUPLICATE_KEY: 'DUPLICATE_KEY',
  RATE_LIMIT: 'RATE_LIMIT',
  PREMIUM_REQUIRED: 'PREMIUM_REQUIRED',
  SUBJECT_LIMIT_REACHED: 'SUBJECT_LIMIT_REACHED',
  EMAIL_VERIFICATION_REQUIRED: 'EMAIL_VERIFICATION_REQUIRED',
  POMODORO_ALREADY_ACTIVE: 'POMODORO_ALREADY_ACTIVE',
  AI_RATE_LIMIT: 'AI_RATE_LIMIT',
  INTERNAL: 'INTERNAL',
} as const;

export type ErrorCode = (typeof ERROR_CODES)[keyof typeof ERROR_CODES];
