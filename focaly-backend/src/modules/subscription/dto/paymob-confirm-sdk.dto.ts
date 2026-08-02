import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class PaymobConfirmSdkDto {
  @ApiProperty({ enum: ['monthly', 'yearly'], example: 'monthly' })
  @IsIn(['monthly', 'yearly'])
  plan!: 'monthly' | 'yearly';

  @ApiProperty({ description: 'Paymob transaction id from native SDK callback' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  transactionId!: string;
}
