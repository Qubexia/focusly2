import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class StartPomodoroDto {
  @ApiPropertyOptional({ example: 'subject-id' })
  @IsOptional()
  @IsString()
  subjectId?: string;

  @ApiPropertyOptional({ example: 25 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(240)
  focusMinutes?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(60)
  breakMinutes?: number;

  @ApiPropertyOptional({ example: 120 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(480)
  sessionMinutes?: number;

  @ApiPropertyOptional({ example: 'cycles', enum: ['cycles', 'middle'] })
  @IsOptional()
  @IsIn(['cycles', 'middle'])
  breakMode?: 'cycles' | 'middle';
}

export class CompletePomodoroDto {
  @ApiProperty({ example: 1 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  cycles?: number;
}
