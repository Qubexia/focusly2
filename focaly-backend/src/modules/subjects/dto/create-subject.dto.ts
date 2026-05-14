import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

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
}
