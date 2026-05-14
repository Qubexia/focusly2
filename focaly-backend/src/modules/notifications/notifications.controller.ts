import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { UpdateSettingsDto } from '../users/dto/update-settings.dto';
import { UsersService } from '../users/users.service';

import { NotificationsRepository } from './notifications.repository';

@ApiTags('Notifications')
@Controller({ path: 'notifications', version: '1' })
export class NotificationsController {
  constructor(
    private readonly notificationsRepo: NotificationsRepository,
    private readonly usersService: UsersService,
  ) {}

  @Get()
  async findAll(
    @CurrentUser() user: CurrentUserPayload,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.notificationsRepo.findAllByUser(user.id, limit ? Number(limit) : 50, cursor);
  }

  @Patch(':id/read')
  async markRead(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.notificationsRepo.markRead(id);
  }

  @Post('read-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  async markAllRead(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.notificationsRepo.markAllRead(user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    await this.notificationsRepo.hardDelete(id);
  }

  @Get('preferences')
  async getPreferences(@CurrentUser() user: CurrentUserPayload) {
    return this.usersService.getCurrentUser(user).then((u: any) => u.settings?.notifications);
  }

  @Patch('preferences')
  async updatePreferences(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: UpdateSettingsDto,
  ) {
    return this.usersService.updateSettings(user, dto);
  }
}
