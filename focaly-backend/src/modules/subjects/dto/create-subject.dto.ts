import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsIn, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateSubjectDto {
  @ApiProperty({ example: 'Physics 101' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({ example: '#FF5733' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'book' })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1440)
  dailyTargetMinutes?: number;

  @ApiPropertyOptional({ example: 'daily', enum: ['daily', 'weekly'] })
  @IsOptional()
  @IsIn(['daily', 'weekly'])
  goalType?: 'daily' | 'weekly';

  @ApiPropertyOptional({ example: [0, 1, 2], description: 'Days of week 0=Sun..6=Sat' })
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  goalDays?: number[];
}
