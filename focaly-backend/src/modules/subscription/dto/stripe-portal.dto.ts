import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class StripePortalDto {
  @ApiProperty()
  @IsString()
  customerId!: string;
}
