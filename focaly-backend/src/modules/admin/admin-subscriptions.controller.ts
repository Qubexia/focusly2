import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminSubscriptionsService } from './admin-subscriptions.service';
import {
  ExtendSubscriptionDto,
  ListSubscriptionsQueryDto,
  RevenueQueryDto,
} from './dto/admin-subscriptions.dto';

@ApiTags('Admin / Subscriptions')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/subscriptions', version: '1' })
export class AdminSubscriptionsController {
  constructor(private readonly service: AdminSubscriptionsService) {}

  @Get()
  list(@Query() query: ListSubscriptionsQueryDto): Promise<unknown> {
    return this.service.list(query);
  }

  @Get('revenue/summary')
  revenue(@Query() query: RevenueQueryDto): Promise<unknown> {
    return this.service.revenueSummary(query);
  }

  @Get(':userId')
  getByUser(@Param('userId') userId: string): Promise<unknown> {
    return this.service.getByUserId(userId);
  }

  @Post(':userId/extend')
  extend(@Param('userId') userId: string, @Body() dto: ExtendSubscriptionDto): Promise<unknown> {
    return this.service.extend(userId, dto);
  }

  @Post(':userId/cancel')
  cancel(@Param('userId') userId: string): Promise<unknown> {
    return this.service.cancel(userId);
  }
}
