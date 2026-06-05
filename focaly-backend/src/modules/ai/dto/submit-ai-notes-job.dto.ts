import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsOptional, IsString, ValidateIf } from 'class-validator';

export class SubmitAiNotesJobDto {
  @ApiPropertyOptional({ example: '64afc1e2...' })
  @IsString()
  @IsOptional()
  subjectId?: string;

  @ApiPropertyOptional({ example: '64afc1e2...' })
  @IsString()
  @IsOptional()
  chapterId?: string;

  @ApiPropertyOptional({ example: ['uploads/user/ai-notes-image/abc.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageKeys?: string[];

  @ApiPropertyOptional({ example: ['uploads/user/chapter-pdf/abc.pdf'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  pdfKeys?: string[];

  @ApiPropertyOptional({ example: 'auto', description: 'auto | ar | en | fr' })
  @IsString()
  @IsOptional()
  language?: string;

  @ApiPropertyOptional({ example: 'medium', description: 'short | medium | long' })
  @IsString()
  @IsOptional()
  detailLevel?: string;

  // At least one source (images or PDFs) is required.
  @ValidateIf((o: SubmitAiNotesJobDto) => !o.imageKeys?.length && !o.pdfKeys?.length)
  @IsString({ message: 'Provide at least one imageKey or pdfKey.' })
  readonly _atLeastOneSource?: never;
}
