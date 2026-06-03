import { IsIn, IsMongoId, IsOptional } from 'class-validator';

import { PaginationQueryDto } from './pagination.dto';

export class ListSubjectsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsMongoId()
  userId?: string;
}

export class ListPlannedItemsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsMongoId()
  userId?: string;

  @IsOptional()
  @IsIn(['task', 'revision', 'lecture', 'exam'])
  kind?: string;
}

export class ListAiJobsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsMongoId()
  userId?: string;

  @IsOptional()
  @IsIn(['queued', 'processing', 'completed', 'failed'])
  status?: string;
}
