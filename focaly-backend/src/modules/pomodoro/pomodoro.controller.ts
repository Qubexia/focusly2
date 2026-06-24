import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';

import { StartPomodoroDto } from './dto';
import { PomodoroService } from './pomodoro.service';

@ApiTags('Pomodoro')
@Controller({ path: 'pomodoro', version: '1' })
export class PomodoroController {
  constructor(private readonly service: PomodoroService) {}

  @Post('start')
  start(@CurrentUser() user: CurrentUserPayload, @Body() dto: StartPomodoroDto) {
    return this.service.start(
      user.id,
      dto.subjectId,
      dto.focusMinutes ?? 25,
      dto.breakMinutes ?? 5,
      dto.sessionMinutes ?? 120,
      dto.breakMode ?? 'cycles',
    );
  }

  @Post(':id/pause')
  pause(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.service.pause(user.id, id);
  }

  @Post(':id/resume')
  resume(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.service.resume(user.id, id);
  }

  @Post(':id/complete')
  complete(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.service.complete(user.id, id);
  }

  @Post(':id/abort')
  abort(@CurrentUser() user: CurrentUserPayload, @Param('id') id: string) {
    return this.service.abort(user.id, id);
  }

  @Get('today')
  today(@CurrentUser() user: CurrentUserPayload) {
    return this.service.today(user.id);
  }

  @Get('history')
  history(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.service.history(user.id, from, to, cursor, limit ? Number(limit) : 20);
  }
}
