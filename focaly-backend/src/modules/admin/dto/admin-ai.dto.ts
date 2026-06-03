import { Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpdateAiSettingsDto {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  /** New OpenAI API key. Send an empty string to clear it (fall back to env). */
  @IsOptional()
  @IsString()
  @MaxLength(200)
  apiKey?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  model?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(2)
  temperature?: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  systemPrompt?: string;
}

export class TestAiConnectionDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  apiKey?: string;
}
