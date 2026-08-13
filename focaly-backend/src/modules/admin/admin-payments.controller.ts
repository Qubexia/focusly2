import { Controller, Get, Param, Query, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminAuditInterceptor } from '../../common/interceptors/admin-audit.interceptor';

import { AdminPaymentsService } from './admin-payments.service';
import { ListPaymentsQueryDto, RevenueReportQueryDto } from './dto/admin-payments.dto';

@ApiTags('Admin / Payments')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@UseInterceptors(AdminAuditInterceptor)
@Controller({ path: 'admin/payments', version: '1' })
export class AdminPaymentsController {
  constructor(private readonly service: AdminPaymentsService) {}

  @Get()
  list(@Query() query: ListPaymentsQueryDto): Promise<unknown> {
    return this.service.list(query);
  }

  @Get('revenue')
  revenue(@Query() query: RevenueReportQueryDto): Promise<unknown> {
    return this.service.revenue(query);
  }

  @Get(':id')
  getOne(@Param('id') id: string): Promise<unknown> {
    return this.service.getById(id);
  }
}
