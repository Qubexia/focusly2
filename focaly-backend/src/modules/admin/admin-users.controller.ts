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
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminUsersService } from './admin-users.service';
import { ListUsersQueryDto, UpdateUserAdminDto } from './dto/admin-users.dto';

@ApiTags('Admin / Users')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/users', version: '1' })
export class AdminUsersController {
  constructor(private readonly service: AdminUsersService) {}

  @Get()
  list(@Query() query: ListUsersQueryDto): Promise<unknown> {
    return this.service.list(query);
  }

  @Get(':id')
  getOne(@Param('id') id: string): Promise<unknown> {
    return this.service.getById(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateUserAdminDto): Promise<unknown> {
    return this.service.update(id, dto);
  }

  @Post(':id/ban')
  ban(@Param('id') id: string): Promise<unknown> {
    return this.service.setBanned(id, true);
  }

  @Post(':id/unban')
  unban(@Param('id') id: string): Promise<unknown> {
    return this.service.setBanned(id, false);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string): Promise<void> {
    await this.service.remove(id);
  }

  @Get(':id/sessions')
  sessions(@Param('id') id: string): Promise<unknown> {
    return this.service.listSessions(id);
  }

  @Delete(':id/sessions/:sessionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async revokeSession(
    @Param('id') id: string,
    @Param('sessionId') sessionId: string,
  ): Promise<void> {
    await this.service.revokeSession(id, sessionId);
  }
}
