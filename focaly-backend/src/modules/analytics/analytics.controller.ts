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
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.summary(user.id, fromDate, toDate);
  }

  @Get('by-subject')
  async getBySubject(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.bySubject(user.id, fromDate, toDate);
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
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.performance(user.id, fromDate, toDate);
  }

  private enforceRange(user: CurrentUserPayload, from: Date, to: Date): void {
    if (user.plan === 'premium') return;

    const tz = 'UTC';
    const now = dayjs().tz(tz);
    const weekStart = now.startOf('week').toDate();
    const weekEnd = now.endOf('week').toDate();

    if (from < weekStart || to > weekEnd) {
      throw new ForbiddenException({
        code: ERROR_CODES.PREMIUM_REQUIRED,
        message: 'Free users can only access the current week. Upgrade to premium for full analytics.',
      });
    }
  }

  private resolveRange(from?: string, to?: string): { fromDate: Date; toDate: Date } {
    const now = dayjs();
    const parsedFrom = from ? dayjs(from) : null;
    const parsedTo = to ? dayjs(to) : null;

    const toDate = parsedTo?.isValid() == true
        ? parsedTo.endOf('day').toDate()
        : now.endOf('day').toDate();
    const fromDate = parsedFrom?.isValid() == true
        ? parsedFrom.startOf('day').toDate()
        : dayjs(toDate).subtract(6, 'day').startOf('day').toDate();

    return { fromDate, toDate };
  }
}
