import { Controller, ForbiddenException, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import dayjs from 'dayjs';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { PremiumGuard } from '../../common/guards/premium.guard';

import { AnalyticsService } from './analytics.service';

@ApiTags('Analytics')
@Controller({ path: 'analytics', version: '1' })
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('summary')
  async getSummary(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    this.enforceRange(user, from, to);
    return this.analyticsService.summary(user.id, new Date(from), new Date(to));
  }

  @Get('by-subject')
  async getBySubject(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    this.enforceRange(user, from, to);
    return this.analyticsService.bySubject(user.id, new Date(from), new Date(to));
  }

  @Get('heatmap')
  async getHeatmap(
    @CurrentUser() user: CurrentUserPayload,
    @Query('year') year: string,
  ) {
    return this.analyticsService.heatmap(user.id, Number(year));
  }

  @Get('performance')
  async getPerformance(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    this.enforceRange(user, from, to);
    return this.analyticsService.performance(user.id, new Date(from), new Date(to));
  }

  private enforceRange(user: CurrentUserPayload, from: string, to: string): void {
    if (user.plan === 'premium') return;

    const tz = 'UTC';
    const now = dayjs().tz(tz);
    const weekStart = now.startOf('week').toDate();
    const weekEnd = now.endOf('week').toDate();

    if (new Date(from) < weekStart || new Date(to) > weekEnd) {
      throw new ForbiddenException({
        code: ERROR_CODES.PREMIUM_REQUIRED,
        message: 'Free users can only access the current week. Upgrade to premium for full analytics.',
      });
    }
  }
}
