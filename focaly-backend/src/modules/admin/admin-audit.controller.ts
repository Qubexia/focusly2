import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminAuditService } from './admin-audit.service';
import { ListAuditLogsQueryDto } from './dto/admin-audit.dto';

@ApiTags('Admin / Audit')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/audit-logs', version: '1' })
export class AdminAuditController {
  constructor(private readonly service: AdminAuditService) {}

  @Get()
  list(@Query() query: ListAuditLogsQueryDto): Promise<unknown> {
    return this.service.list(query);
  }

  @Get('event-types')
  eventTypes(): Promise<string[]> {
    return this.service.eventTypes();
  }
}
