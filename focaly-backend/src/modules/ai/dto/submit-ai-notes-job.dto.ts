import { ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsOptional, IsString } from 'class-validator';

export class SubmitAiNotesJobDto {
  @ApiProperty({ example: '64afc1e2...' })
  @IsString()
  @IsOptional()
  subjectId?: string;

  @ApiProperty({ example: ['uploads/user/lecture-image/abc.jpg'] })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  imageKeys!: string[];
}
