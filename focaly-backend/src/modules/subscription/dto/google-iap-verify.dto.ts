import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class GoogleIapVerifyDto {
  @ApiProperty()
  @IsString()
  packageName!: string;

  @ApiProperty()
  @IsString()
  productId!: string;

  @ApiProperty()
  @IsString()
  purchaseToken!: string;
}
