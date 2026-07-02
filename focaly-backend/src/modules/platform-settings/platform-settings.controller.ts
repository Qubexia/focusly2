import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../../common/decorators/public.decorator';

import { PlatformSettingsService } from './platform-settings.service';

@ApiTags('Config')
@Controller({ path: 'config', version: '1' })
export class PlatformSettingsController {
  constructor(private readonly platformSettings: PlatformSettingsService) {}

  /** Public platform config for mobile/web clients. */
  @Public()
  @Get()
  getPublicConfig(): Promise<unknown> {
    return this.platformSettings.publicConfig();
  }
}
