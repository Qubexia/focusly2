import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminNotificationsService } from './admin-notifications.service';
import { BroadcastNotificationDto } from './dto/admin-notifications.dto';

@ApiTags('Admin / Notifications')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/notifications', version: '1' })
export class AdminNotificationsController {
  constructor(private readonly service: AdminNotificationsService) {}

  @Post('broadcast')
  broadcast(@Body() dto: BroadcastNotificationDto): Promise<unknown> {
    return this.service.broadcast(dto);
  }

  @Get('broadcasts')
  recent(): Promise<unknown> {
    return this.service.listRecent();
  }
}
