import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class CompleteScheduleDto {
  /** The local occurrence date being marked complete, 'YYYY-MM-DD'. */
  @ApiProperty({ example: '2026-06-20' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be formatted as YYYY-MM-DD' })
  date!: string;
}
