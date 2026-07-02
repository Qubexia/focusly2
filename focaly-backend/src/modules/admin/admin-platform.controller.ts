import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';

import { UpdatePlatformSettingsDto } from './dto/admin-platform.dto';

@ApiTags('Admin / Platform')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/platform', version: '1' })
export class AdminPlatformController {
  constructor(private readonly platformSettings: PlatformSettingsService) {}

  @Get('settings')
  getSettings(): Promise<unknown> {
    return this.platformSettings.publicConfig();
  }

  @Patch('settings')
  updateSettings(@Body() dto: UpdatePlatformSettingsDto): Promise<unknown> {
    return this.platformSettings.update(dto);
  }
}
