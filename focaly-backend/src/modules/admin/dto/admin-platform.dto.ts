import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

export class UpdatePlatformSettingsDto {
  @IsOptional()
  @IsBoolean()
  premiumGatingEnabled?: boolean;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100)
  freeSubjectLimit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(1000)
  aiHourlyLimit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10000)
  aiMonthlyLimit?: number;

  @IsOptional()
  @IsBoolean()
  maintenanceMode?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  maintenanceMessage?: string | null;

  /** Premium monthly price in the smallest currency unit. null → use the env var. */
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100_000_000)
  premiumMonthlyPriceCents?: number | null;

  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100_000_000)
  premiumYearlyPriceCents?: number | null;

  /** ISO-4217 code, e.g. EGP. null → use the env var. */
  @IsOptional()
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Length(3, 3)
  currency?: string | null;
}
