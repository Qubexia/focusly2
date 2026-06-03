import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AiSettingsService } from '../ai/ai-settings.service';

import { TestAiConnectionDto, UpdateAiSettingsDto } from './dto/admin-ai.dto';

@ApiTags('Admin / AI')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/ai', version: '1' })
export class AdminAiController {
  constructor(private readonly aiSettings: AiSettingsService) {}

  @Get('settings')
  getSettings(): Promise<unknown> {
    return this.aiSettings.masked();
  }

  @Patch('settings')
  updateSettings(@Body() dto: UpdateAiSettingsDto): Promise<unknown> {
    return this.aiSettings.update(dto);
  }

  @Post('test')
  testConnection(@Body() dto: TestAiConnectionDto): Promise<unknown> {
    return this.aiSettings.testConnection(dto.apiKey);
  }
}
