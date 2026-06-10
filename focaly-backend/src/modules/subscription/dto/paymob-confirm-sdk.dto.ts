import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString } from 'class-validator';

export class PaymobConfirmSdkDto {
  @ApiProperty({ enum: ['monthly', 'yearly'], example: 'monthly' })
  @IsIn(['monthly', 'yearly'])
  plan!: 'monthly' | 'yearly';

  @ApiPropertyOptional({ description: 'Paymob transaction id from native SDK callback' })
  @IsOptional()
  @IsString()
  transactionId?: string;
}
