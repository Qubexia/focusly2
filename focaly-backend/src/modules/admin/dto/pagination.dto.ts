import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class PaginationQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  pages: number;
}

/** Normalises page/limit and returns the mongo skip/limit window. */
export function resolvePaging(page = 1, limit = 20): { page: number; limit: number; skip: number } {
  const safePage = Math.max(1, Math.floor(page));
  const safeLimit = Math.min(100, Math.max(1, Math.floor(limit)));
  return { page: safePage, limit: safeLimit, skip: (safePage - 1) * safeLimit };
}

export function paginated<T>(items: T[], total: number, page: number, limit: number): Paginated<T> {
  return { items, total, page, limit, pages: Math.max(1, Math.ceil(total / limit)) };
}
