import dayjs from 'dayjs';
import timezone from 'dayjs/plugin/timezone';
import utc from 'dayjs/plugin/utc';

dayjs.extend(utc);
dayjs.extend(timezone);

export const DEFAULT_TIMEZONE = 'UTC';

/**
 * Every "which day is this?" decision in the app (streaks, daily charts,
 * today's focus total) has to be made in the user's own calendar, not the
 * server's. Import dayjs from here so the utc/timezone plugins are guaranteed
 * to be loaded before `.tz()` is called.
 */
export { dayjs };

/** Falls back to UTC for users who never reported a timezone. */
export function resolveTimezone(tz?: string | null): string {
  if (!tz) return DEFAULT_TIMEZONE;
  try {
    dayjs().tz(tz);
    return tz;
  } catch {
    return DEFAULT_TIMEZONE;
  }
}

/** `YYYY-MM-DD` of the given instant in the user's calendar. */
export function localDayKey(date: Date | string | number, tz: string): string {
  return dayjs(date).tz(resolveTimezone(tz)).format('YYYY-MM-DD');
}

/** Today's `YYYY-MM-DD` in the user's calendar. */
export function todayKey(tz: string): string {
  return dayjs().tz(resolveTimezone(tz)).format('YYYY-MM-DD');
}

/** Yesterday's `YYYY-MM-DD` in the user's calendar. */
export function yesterdayKey(tz: string): string {
  return dayjs().tz(resolveTimezone(tz)).subtract(1, 'day').format('YYYY-MM-DD');
}

/**
 * Converts a `YYYY-MM-DD` day span in the user's calendar into the UTC instants
 * that bound it, which is what Mongo actually compares against.
 */
export function localDayBounds(
  from: Date | string,
  to: Date | string,
  tz: string,
): { start: Date; end: Date } {
  const zone = resolveTimezone(tz);
  const fromKey = dayjs(from).tz(zone).format('YYYY-MM-DD');
  const toKey = dayjs(to).tz(zone).format('YYYY-MM-DD');

  return {
    start: dayjs.tz(fromKey, zone).startOf('day').toDate(),
    end: dayjs.tz(toKey, zone).endOf('day').toDate(),
  };
}

/** Start/end of the day that `date` falls in, in the user's calendar. */
export function localDayRange(date: Date | string, tz: string): { start: Date; end: Date } {
  return localDayBounds(date, date, tz);
}

/** Inclusive count of local days covered by the span. */
export function localDayCount(from: Date | string, to: Date | string, tz: string): number {
  const zone = resolveTimezone(tz);
  const fromKey = dayjs(from).tz(zone).format('YYYY-MM-DD');
  const toKey = dayjs(to).tz(zone).format('YYYY-MM-DD');
  return Math.max(1, dayjs(toKey).diff(dayjs(fromKey), 'day') + 1);
}

/** Every `YYYY-MM-DD` between the two instants, inclusive, in the user's calendar. */
export function localDayKeysBetween(from: Date | string, to: Date | string, tz: string): string[] {
  const zone = resolveTimezone(tz);
  const start = dayjs(dayjs(from).tz(zone).format('YYYY-MM-DD'));
  const end = dayjs(dayjs(to).tz(zone).format('YYYY-MM-DD'));

  const keys: string[] = [];
  for (let cursor = start; !cursor.isAfter(end); cursor = cursor.add(1, 'day')) {
    keys.push(cursor.format('YYYY-MM-DD'));
  }
  return keys;
}
