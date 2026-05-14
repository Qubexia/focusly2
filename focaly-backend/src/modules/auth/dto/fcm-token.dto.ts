import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class FcmTokenDto {
  @ApiProperty({ example: 'fcm-token-123' })
  @IsString()
  fcmToken!: string;
}
