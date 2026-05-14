import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({ example: 'reset-token' })
  @IsString()
  token!: string;

  @ApiProperty({ example: 'newsecure123' })
  @IsString()
  @MinLength(8)
  newPassword!: string;
}
