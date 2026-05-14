import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CreateScheduleDto {
  @ApiProperty({ example: 'Weekly physics review' })
  @IsString()
  title!: string;

  @ApiProperty({ example: '2026-05-15T09:00:00Z' })
  @IsDateString()
  startAt!: string;

  @ApiPropertyOptional({ example: '2026-06-15T09:00:00Z' })
  @IsOptional()
  @IsDateString()
  endAt?: string;

  @ApiProperty({ example: [1, 3, 5] })
  @IsArray()
  @ArrayMinSize(1)
  @IsNumber({}, { each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  daysOfWeek!: number[];

  @ApiPropertyOptional({ example: 'FREQ=WEEKLY;BYDAY=MO,WE,FR' })
  @IsOptional()
  @IsString()
  rrule?: string;

  @ApiPropertyOptional({ example: 15 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  reminderMinutesBefore?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  reminderEnabled?: boolean;
}
