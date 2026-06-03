import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminAnalyticsService } from './admin-analytics.service';
import { SignupsQueryDto } from './dto/admin-analytics.dto';

@ApiTags('Admin / Analytics')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/analytics', version: '1' })
export class AdminAnalyticsController {
  constructor(private readonly service: AdminAnalyticsService) {}

  @Get('overview')
  overview(): Promise<unknown> {
    return this.service.overview();
  }

  @Get('signups')
  signups(@Query() query: SignupsQueryDto): Promise<unknown> {
    return this.service.signups(query);
  }
}
