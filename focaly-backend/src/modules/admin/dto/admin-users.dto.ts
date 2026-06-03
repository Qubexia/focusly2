import {
  IsBoolean,
  IsIn,
  IsISO8601,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

import { PaginationQueryDto } from './pagination.dto';

export class ListUsersQueryDto extends PaginationQueryDto {
  /** Free-text search across email and name. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  q?: string;

  @IsOptional()
  @IsIn(['free', 'premium'])
  plan?: 'free' | 'premium';

  @IsOptional()
  @IsIn(['user', 'admin'])
  role?: 'user' | 'admin';

  @IsOptional()
  @IsIn(['active', 'banned', 'deleted'])
  status?: 'active' | 'banned' | 'deleted';
}

export class UpdateUserAdminDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsIn(['user', 'admin'])
  role?: 'user' | 'admin';

  @IsOptional()
  @IsIn(['free', 'premium'])
  plan?: 'free' | 'premium';

  @IsOptional()
  @IsBoolean()
  emailVerified?: boolean;

  /** ISO date string, or null to clear premium expiry. */
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsISO8601()
  premiumUntil?: string | null;
}
