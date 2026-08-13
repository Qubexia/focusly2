import { Controller, ForbiddenException, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { dayjs, resolveTimezone } from '../../common/utils/day.util';
import { PlatformSettingsService } from '../platform-settings/platform-settings.service';
import { UsersRepository } from '../users/users.repository';

import { AnalyticsService } from './analytics.service';

@ApiTags('Analytics')
@Controller({ path: 'analytics', version: '1' })
export class AnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly platformSettings: PlatformSettingsService,
    private readonly usersRepo: UsersRepository,
  ) {}

  @Get('summary')
  async getSummary(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    await this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.summary(user.id, fromDate, toDate);
  }

  @Get('by-subject')
  async getBySubject(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    await this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.bySubject(user.id, fromDate, toDate);
  }

  @Get('heatmap')
  async getHeatmap(@CurrentUser() user: CurrentUserPayload, @Query('year') year: string) {
    return this.analyticsService.heatmap(user.id, Number(year));
  }

  @Get('performance')
  async getPerformance(
    @CurrentUser() user: CurrentUserPayload,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const { fromDate, toDate } = this.resolveRange(from, to);
    await this.enforceRange(user, fromDate, toDate);
    return this.analyticsService.performance(user.id, fromDate, toDate);
  }

  /**
   * Free users are limited to the current week — but only while premium gating
   * is switched on for the platform, and the week is measured in the user's own
   * calendar so a late-night session is not read as "last week".
   */
  private async enforceRange(user: CurrentUserPayload, from: Date, to: Date): Promise<void> {
    if (this.hasActivePremium(user)) return;

    const settings = await this.platformSettings.resolve();
    if (!settings.premiumGatingEnabled) return;

    const tz = await this.timezoneFor(user.id);
    const now = dayjs().tz(tz);
    const weekStart = now.startOf('week').toDate();
    const weekEnd = now.endOf('week').toDate();

    if (from < weekStart || to > weekEnd) {
      throw new ForbiddenException({
        code: ERROR_CODES.PREMIUM_REQUIRED,
        message:
          'Free users can only access the current week. Upgrade to premium for full analytics.',
      });
    }
  }

  private hasActivePremium(user: CurrentUserPayload): boolean {
    if (user.plan !== 'premium') return false;
    if (user.premiumUntil === undefined || user.premiumUntil === null) return true;
    return new Date(user.premiumUntil) > new Date();
  }

  private async timezoneFor(userId: string): Promise<string> {
    const record = await this.usersRepo.findActiveById(userId);
    return resolveTimezone(record?.settings?.timezone);
  }

  private resolveRange(from?: string, to?: string): { fromDate: Date; toDate: Date } {
    const now = dayjs();
    const parsedFrom = from ? dayjs(from) : null;
    const parsedTo = to ? dayjs(to) : null;

    const toDate =
      parsedTo?.isValid() == true ? parsedTo.endOf('day').toDate() : now.endOf('day').toDate();
    const fromDate =
      parsedFrom?.isValid() == true
        ? parsedFrom.startOf('day').toDate()
        : dayjs(toDate).subtract(6, 'day').startOf('day').toDate();

    return { fromDate, toDate };
  }
}
