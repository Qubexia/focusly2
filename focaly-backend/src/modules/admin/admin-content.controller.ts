import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { AdminContentService } from './admin-content.service';
import {
  ListAiJobsQueryDto,
  ListPlannedItemsQueryDto,
  ListSubjectsQueryDto,
} from './dto/admin-content.dto';

@ApiTags('Admin / Content')
@ApiBearerAuth('bearerAccess')
@Roles('admin')
@UseGuards(RolesGuard)
@Controller({ path: 'admin/content', version: '1' })
export class AdminContentController {
  constructor(private readonly service: AdminContentService) {}

  @Get('subjects')
  subjects(@Query() query: ListSubjectsQueryDto): Promise<unknown> {
    return this.service.listSubjects(query);
  }

  @Get('planned-items')
  plannedItems(@Query() query: ListPlannedItemsQueryDto): Promise<unknown> {
    return this.service.listPlannedItems(query);
  }

  @Get('ai-jobs')
  aiJobs(@Query() query: ListAiJobsQueryDto): Promise<unknown> {
    return this.service.listAiJobs(query);
  }
}
