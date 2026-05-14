import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class GoogleLoginDto {
  @ApiProperty({ example: 'google-id-token' })
  @IsString()
  idToken!: string;

  @ApiProperty({ example: 'pixel-9' })
  @IsString()
  deviceId!: string;

  @ApiPropertyOptional({ example: 'fcm-token-123' })
  @IsOptional()
  @IsString()
  fcmToken?: string;
}
