import { Type } from 'class-transformer';
import { IsIn, IsInt, IsISO8601, IsOptional, Max, Min } from 'class-validator';

import { PaginationQueryDto } from './pagination.dto';

export class ListSubscriptionsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsIn(['trialing', 'active', 'past_due', 'canceled', 'expired'])
  status?: string;

  @IsOptional()
  @IsIn(['stripe', 'google_play', 'app_store', 'paymob'])
  provider?: string;
}

export class ExtendSubscriptionDto {
  /** Number of days to extend premium access from now (or from current expiry). */
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(3650)
  days!: number;
}

export class RevenueQueryDto {
  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}
