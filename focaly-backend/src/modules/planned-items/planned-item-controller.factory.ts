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
  Type,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';

import { CreatePlannedItemDto, UpdatePlannedItemDto } from './dto';
import { PlannedItemsService } from './planned-items.service';
import { PlannedItemKind } from './schemas/planned-item.schema';

export function createPlannedItemController(
  kind: PlannedItemKind,
  route: string,
  tag: string,
): Type<any> {
  @ApiTags(tag)
  @Controller({ path: route, version: '1' })
  class PlannedItemController {
    constructor(private readonly service: PlannedItemsService) {}

    @Post()
    create(@CurrentUser() user: CurrentUserPayload, @Body() dto: CreatePlannedItemDto) {
      return this.service.create(user.id, kind, dto);
    }

    @Get()
    findAll(
      @CurrentUser() user: CurrentUserPayload,
    ) {
      return this.service.findAll(user.id, kind);
    }

    @Get(':id')
    findOne(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
      return this.service.findOne(user.id, kind, id);
    }

    @Patch(':id')
    update(
      @CurrentUser() user: CurrentUserPayload,
      @Param('id') id: string,
      @Body() dto: UpdatePlannedItemDto,
    ) {
      return this.service.update(user.id, kind, id, dto);
    }

    @Post(':id/complete')
    complete(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
      return this.service.complete(user.id, kind, id);
    }

    @Delete(':id')
    @HttpCode(HttpStatus.NO_CONTENT)
    async remove(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string): Promise<void> {
      await this.service.remove(user.id, kind, id);
    }
  }

  return PlannedItemController;
}

export const TasksController = createPlannedItemController('task', 'tasks', 'Tasks');
export const RevisionsController = createPlannedItemController('revision', 'revisions', 'Revisions');
export const LecturesController = createPlannedItemController('lecture', 'lectures', 'Lectures');
export const ExamsController = createPlannedItemController('exam', 'exams', 'Exams');
