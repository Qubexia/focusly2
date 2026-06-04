import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class PaymobCardPayDto {
  @ApiProperty({ example: 'Mohamed Ali' })
  @IsString()
  @IsNotEmpty()
  @Length(2, 64)
  name!: string;

  @ApiProperty({ example: '4111111111111111' })
  @IsString()
  @Matches(/^\d{12,19}$/)
  number!: string;

  @ApiProperty({ example: '12' })
  @IsString()
  @Matches(/^\d{2}$/)
  expiryMonth!: string;

  @ApiProperty({ example: '25' })
  @IsString()
  @Matches(/^\d{2}$/)
  expiryYear!: string;

  @ApiProperty({ example: '123' })
  @IsString()
  @Matches(/^\d{3,4}$/)
  cvv!: string;
}
