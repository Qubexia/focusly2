import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsDateString, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreatePlannedItemDto {
  @ApiProperty({ example: 'Review Chapter 3' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({ example: '64afc1e2...' })
  @IsOptional()
  @IsString()
  subjectId?: string;

  @ApiPropertyOptional({ example: 'Focus on formulas' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ example: '2026-05-20T14:00:00Z' })
  @IsDateString()
  plannedAt!: string;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  durationMinutes?: number;

  @ApiPropertyOptional({ example: 'once', enum: ['daily', 'weekly', 'once'] })
  @IsOptional()
  @IsString()
  recurrence?: string;

  @ApiPropertyOptional({ example: 15 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  reminderMinutesBefore?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  reminderEnabled?: boolean;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  rewardPoints?: number;
}
