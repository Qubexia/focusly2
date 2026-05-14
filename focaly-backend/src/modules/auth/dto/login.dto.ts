import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'supersecure123' })
  @IsString()
  password!: string;

  @ApiProperty({ example: 'iphone-15-pro' })
  @IsString()
  deviceId!: string;

  @ApiPropertyOptional({ example: 'fcm-token-123' })
  @IsOptional()
  @IsString()
  fcmToken?: string;
}
