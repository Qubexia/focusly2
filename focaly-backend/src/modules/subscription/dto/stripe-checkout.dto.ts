import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class StripeCheckoutDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  priceId?: string;
}
