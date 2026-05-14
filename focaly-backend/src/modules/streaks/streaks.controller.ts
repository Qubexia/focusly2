import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';

import { StreaksService } from './streaks.service';

@ApiTags('Streaks')
@Controller({ path: 'streaks', version: '1' })
export class StreaksController {
  constructor(private readonly service: StreaksService) {}

  @Get('me')
  getMyStreak(@CurrentUser() user: CurrentUserPayload) {
    return this.service.getStreak(user.id);
  }
}
