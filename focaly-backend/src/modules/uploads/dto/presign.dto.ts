import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString, Max, Min } from 'class-validator';

export class PresignDto {
  @ApiProperty({ example: 'lecture-image' })
  @IsString()
  kind!: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  mimeType!: string;

  @ApiProperty({ example: 1024000 })
  @IsNumber()
  @Min(1)
  @Max(10_485_760)
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
