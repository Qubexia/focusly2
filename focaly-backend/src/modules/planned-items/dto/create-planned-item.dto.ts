import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

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
  @IsIn(['daily', 'weekly', 'once'])
  recurrence?: string;

  @ApiPropertyOptional({
    example: [0, 3],
    description: 'Weekdays a weekly recurrence repeats on, Sun=0..Sat=6.',
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  daysOfWeek?: number[];

  @ApiPropertyOptional({ example: '2026-12-31T00:00:00Z' })
  @IsOptional()
  @IsDateString()
  recurrenceEndAt?: string;

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
