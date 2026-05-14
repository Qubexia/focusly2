import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class RefreshDto {
  @ApiProperty({ example: 'refresh-token' })
  @IsString()
  refreshToken!: string;

  @ApiProperty({ example: 'iphone-15-pro' })
  @IsString()
  deviceId!: string;
}
