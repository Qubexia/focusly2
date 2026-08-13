import { IsIn, IsISO8601, IsMongoId, IsOptional, IsString, MaxLength } from 'class-validator';

import { PaginationQueryDto } from './pagination.dto';

export class ListAuditLogsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsIn(['user', 'admin', 'system', 'webhook'])
  actor?: string;

  /** Exact event type, or a prefix such as `admin.users`. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  eventType?: string;

  /** The account the action was performed on. */
  @IsOptional()
  @IsMongoId()
  userId?: string;

  /** The admin who performed the action. */
  @IsOptional()
  @IsMongoId()
  actorUserId?: string;

  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}
