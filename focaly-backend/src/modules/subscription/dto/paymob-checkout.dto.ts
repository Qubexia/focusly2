import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class PaymobCheckoutDto {
  @ApiProperty({ enum: ['monthly', 'yearly'], example: 'monthly' })
  @IsIn(['monthly', 'yearly'])
  plan!: 'monthly' | 'yearly';

  /** LAN/public URL the phone browser can reach (e.g. http://192.168.1.3:5000). */
  @ApiPropertyOptional({ example: 'http://192.168.1.3:5000' })
  @IsOptional()
  @IsString()
  @Matches(/^https?:\/\/.+/i)
  checkoutBaseUrl?: string;
}
