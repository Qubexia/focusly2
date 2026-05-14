import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'student@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'supersecure123' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ example: 'Maha Ali' })
  @IsString()
  name!: string;
}
