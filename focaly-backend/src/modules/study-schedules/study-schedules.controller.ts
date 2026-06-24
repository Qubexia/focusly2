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

import { CompleteScheduleDto, CreateScheduleDto, UpdateScheduleDto } from './dto';
import { StudySchedulesService } from './study-schedules.service';

@ApiTags('Schedules')
@Controller()
export class StudySchedulesController {
  constructor(private readonly service: StudySchedulesService) {}

  @Post('subjects/:subjectId/schedules')
  async create(
    @CurrentUser() user: CurrentUserPayload,
    @Param('subjectId') subjectId: string,
    @Body() dto: CreateScheduleDto,
  ) {
    return this.service.create(user.id, subjectId, dto);
  }

  @Get('schedules')
  async findAll(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.service.findAll(user.id, from, to);
  }

  @Get('schedules/calendar')
  async calendar(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.service.findAll(user.id, from, to);
  }

  @Get('schedules/completions')
  async completions(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.service.listCompletions(user.id, from, to);
  }

  @Get('schedules/:id')
  async findOne(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.service.findOne(user.id, id);
  }

  @Post('schedules/:id/complete')
  async complete(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
    @Body() dto: CompleteScheduleDto,
  ) {
    return this.service.complete(user.id, id, dto.date);
  }

  @Patch('schedules/:id')
  async update(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
    @Body() dto: UpdateScheduleDto,
  ) {
    return this.service.update(user.id, id, dto);
  }

  @Delete('schedules/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string): Promise<void> {
    await this.service.remove(user.id, id);
  }
}
