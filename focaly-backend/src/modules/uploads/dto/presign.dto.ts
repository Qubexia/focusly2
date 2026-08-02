import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNumber, IsString, Max, Min } from 'class-validator';

export const UPLOAD_KINDS = [
  'lecture-image',
  'ai-notes-image',
  'subject-pdf',
  'chapter-pdf',
  'avatar',
] as const;

export type UploadKind = (typeof UPLOAD_KINDS)[number];

/** Largest per-kind limit; the exact cap is enforced per kind in UploadsService. */
const MAX_UPLOAD_BYTES = 26_214_400;

export class PresignDto {
  @ApiProperty({ enum: UPLOAD_KINDS, example: 'lecture-image' })
  @IsIn(UPLOAD_KINDS)
  kind!: UploadKind;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  mimeType!: string;

  @ApiProperty({ example: 1024000 })
  @IsNumber()
  @Min(1)
  @Max(MAX_UPLOAD_BYTES)
  sizeBytes!: number;
}

export class PresignResponseDto {
  @ApiProperty()
  url!: string;

  @ApiProperty()
  key!: string;
}

export class ConfirmUploadDto {
  @ApiProperty()
  @IsString()
  key!: string;
}
