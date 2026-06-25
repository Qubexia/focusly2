import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
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
import { ERROR_CODES } from '../../common/dto/api-response';

import { ChaptersService } from './chapters.service';
import { CreateChapterDto, CreateSubjectDto, UpdateChapterDto, UpdateSubjectDto } from './dto';
import { SubjectsService } from './subjects.service';

@ApiTags('Subjects')
@Controller({ path: 'subjects', version: '1' })
export class SubjectsController {
  constructor(
    private readonly subjectsService: SubjectsService,
    private readonly chaptersService: ChaptersService,
  ) {}

  @Post()
  async create(@CurrentUser() user: CurrentUserPayload, @Body() dto: CreateSubjectDto) {
    return this.subjectsService.create(user.id, dto);
  }

  @Get()
  async findAll(
    @CurrentUser() user: CurrentUserPayload,
    @Query('includeArchived') includeArchived?: string,
  ) {
    return this.subjectsService.findAll(user.id, includeArchived === 'true');
  }

  @Get(':id')
  async findOne(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.subjectsService.findOne(user.id, id);
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') id: string,
    @Body() dto: UpdateSubjectDto,
  ) {
    return this.subjectsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string): Promise<void> {
    await this.subjectsService.remove(user.id, id);
  }

  @Get(':id/progress')
  async progress(@Param('id') id: string) {
    return this.subjectsService.getProgress(id);
  }

  @Post(':id/chapters')
  async createChapter(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') subjectId: string,
    @Body() dto: CreateChapterDto,
  ) {
    return this.chaptersService.create(user.id, subjectId, dto);
  }

  @Get(':id/chapters')
  async listChapters(@Param('id') subjectId: string) {
    return this.chaptersService.findAll(subjectId);
  }

  @Patch(':id/chapters/:chId')
  async updateChapter(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') subjectId: string,
    @Param('chId') chapterId: string,
    @Body() dto: UpdateChapterDto,
  ) {
    const result = await this.chaptersService.update(user.id, subjectId, chapterId, dto);
    if (!result) {
      throw new ForbiddenException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'Chapter was not found.',
      });
    }
    return result;
  }
}
