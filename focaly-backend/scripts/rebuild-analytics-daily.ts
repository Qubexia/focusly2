import './dev-runtime-flags.cjs';
import { NestFactory } from '@nestjs/core';
import { getModelToken } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { AppModule } from '../src/app.module';
import { localDayBounds, localDayKey, resolveTimezone } from '../src/common/utils/day.util';
import { AnalyticsRepository } from '../src/modules/analytics/analytics.repository';
import { AnalyticsDaily } from '../src/modules/analytics/schemas/analytics-daily.schema';
import { PlannedItem } from '../src/modules/planned-items/schemas/planned-item.schema';
import { PomodoroSession } from '../src/modules/pomodoro/schemas/pomodoro-session.schema';
import { UsersRepository } from '../src/modules/users/users.repository';

/**
 * Rebuilds the `analytics_daily` rollup from the raw sessions and planned
 * items.
 *
 * The old nightly rollup added to counters the live handler had already
 * written, so historical rows are inflated. This recomputes every day from
 * scratch, in each user's own timezone.
 *
 *   npm run rebuild-analytics -- --dry-run
 *   npm run rebuild-analytics
 */
async function main(): Promise<void> {
  const dryRun = process.argv.includes('--dry-run');

  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const analyticsRepo = app.get(AnalyticsRepository);
    const usersRepo = app.get(UsersRepository);
    const dailyModel = app.get<Model<AnalyticsDaily>>(getModelToken(AnalyticsDaily.name));
    const sessionModel = app.get<Model<PomodoroSession>>(getModelToken(PomodoroSession.name));
    const plannedItemModel = app.get<Model<PlannedItem>>(getModelToken(PlannedItem.name));

    const userIds = await sessionModel.distinct('userId', { status: 'completed' });
    console.log(`Rebuilding analytics for ${userIds.length} user(s)${dryRun ? ' (dry run)' : ''}.`);

    let daysWritten = 0;

    for (const rawUserId of userIds) {
      const userId = String(rawUserId);
      const user = await usersRepo.findActiveById(userId);
      if (!user) continue;

      const tz = resolveTimezone(user.settings?.timezone);
      const sessions = await sessionModel
        .find({ userId: rawUserId, status: 'completed' })
        .select('startedAt totalFocusMinutes completedCycles')
        .lean()
        .exec();

      // Group the user's sessions into their own calendar days.
      const perDay = new Map<
        string,
        { focusMinutes: number; completedCycles: number; sessionsCount: number }
      >();

      for (const session of sessions) {
        const key = localDayKey(session.startedAt, tz);
        const bucket = perDay.get(key) ?? {
          focusMinutes: 0,
          completedCycles: 0,
          sessionsCount: 0,
        };
        bucket.focusMinutes += session.totalFocusMinutes ?? 0;
        bucket.completedCycles += session.completedCycles ?? 0;
        bucket.sessionsCount += 1;
        perDay.set(key, bucket);
      }

      // Completed tasks are counted per day too — one-off by timestamp,
      // recurring by the occurrence key the user ticked off.
      const items = await plannedItemModel
        .find({ userId: rawUserId })
        .select('recurrence completed completedAt completedDates')
        .lean()
        .exec();

      const tasksPerDay = new Map<string, number>();
      for (const item of items) {
        if ((item.recurrence ?? 'once') === 'once') {
          if (item.completed && item.completedAt) {
            const key = localDayKey(item.completedAt, tz);
            tasksPerDay.set(key, (tasksPerDay.get(key) ?? 0) + 1);
          }
          continue;
        }
        for (const key of item.completedDates ?? []) {
          tasksPerDay.set(key, (tasksPerDay.get(key) ?? 0) + 1);
        }
      }

      const allKeys = new Set([...perDay.keys(), ...tasksPerDay.keys()]);
      if (allKeys.size === 0) continue;

      if (!dryRun) {
        // Drop the user's stale rows first so days that no longer have any
        // activity do not linger with old totals.
        await dailyModel.deleteMany({ userId: toObjectIdIfPossible(userId) }).exec();
      }

      for (const key of allKeys) {
        const focus = perDay.get(key);
        const { start } = localDayBounds(key, key, 'UTC');

        if (!dryRun) {
          await analyticsRepo.setDay(userId, start, {
            focusMinutes: focus?.focusMinutes ?? 0,
            completedCycles: focus?.completedCycles ?? 0,
            sessionsCount: focus?.sessionsCount ?? 0,
            plannedItemsCompleted: tasksPerDay.get(key) ?? 0,
          });
        }
        daysWritten++;
      }

      console.log(`  ${user.email}: ${allKeys.size} day(s), tz=${tz}`);
    }

    console.log(
      dryRun
        ? `Dry run complete — would rewrite ${daysWritten} day row(s).`
        : `✓ Rebuilt ${daysWritten} day row(s).`,
    );
  } finally {
    await app.close();
  }
}

function toObjectIdIfPossible(value: string): Types.ObjectId | string {
  return Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : value;
}

void main();
