import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class AppleIapVerifyDto {
  @ApiProperty()
  @IsString()
  receiptData!: string;
}
