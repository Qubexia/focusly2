import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsIn,
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export class BroadcastNotificationDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  body?: string;

  @IsOptional()
  @IsIn(['reminder', 'streak', 'reward', 'system'])
  type?: 'reminder' | 'streak' | 'reward' | 'system';

  /** Audience: everyone, by plan, or an explicit list of user ids. */
  @IsIn(['all', 'premium', 'free', 'users'])
  target!: 'all' | 'premium' | 'free' | 'users';

  @ValidateIf((o: BroadcastNotificationDto) => o.target === 'users')
  @IsArray()
  @ArrayNotEmpty()
  @IsMongoId({ each: true })
  @Type(() => String)
  userIds?: string[];

  /** When true also attempts an FCM push to active devices. */
  @IsOptional()
  push?: boolean;
}
