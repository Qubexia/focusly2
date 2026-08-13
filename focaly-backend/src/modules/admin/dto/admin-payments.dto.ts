import { IsIn, IsISO8601, IsMongoId, IsOptional, IsString, MaxLength } from 'class-validator';

import { PaginationQueryDto } from './pagination.dto';

const PROVIDERS = ['paymob', 'google_play', 'app_store', 'stripe'] as const;
const OUTCOMES = ['applied', 'noop', 'error'] as const;

export class ListPaymentsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsIn(PROVIDERS as unknown as string[])
  provider?: string;

  @IsOptional()
  @IsIn(OUTCOMES as unknown as string[])
  outcome?: string;

  @IsOptional()
  @IsIn(['monthly', 'yearly'])
  plan?: string;

  @IsOptional()
  @IsMongoId()
  userId?: string;

  /** Free-text search across the payer's email/name and the provider tx id. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  q?: string;

  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}

export class RevenueReportQueryDto {
  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;

  /** Bucket size for the time series. */
  @IsOptional()
  @IsIn(['day', 'month'])
  interval?: 'day' | 'month';
}
