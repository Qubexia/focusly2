import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

export class PaymobCheckoutDto {
  @ApiProperty({ enum: ['monthly', 'yearly'], example: 'monthly' })
  @IsIn(['monthly', 'yearly'])
  plan!: 'monthly' | 'yearly';
}
