import {
  localDayBounds,
  localDayCount,
  localDayKey,
  localDayKeysBetween,
  resolveTimezone,
} from '../../../src/common/utils/day.util';

describe('Local day boundaries (Africa/Cairo, UTC+3)', () => {
  const CAIRO = 'Africa/Cairo';

  it('files a 1am local session under that local day, not the UTC day before', () => {
    // 2026-07-29 01:30 in Cairo is still 2026-07-28 22:30 in UTC.
    const lateNight = new Date('2026-07-28T22:30:00.000Z');

    expect(localDayKey(lateNight, CAIRO)).toBe('2026-07-29');
    expect(localDayKey(lateNight, 'UTC')).toBe('2026-07-28');
  });

  it('files an 11pm local session under that same local day', () => {
    const evening = new Date('2026-07-28T20:30:00.000Z'); // 23:30 Cairo

    expect(localDayKey(evening, CAIRO)).toBe('2026-07-28');
  });

  it('bounds a local day with the matching UTC instants', () => {
    const { start, end } = localDayBounds('2026-07-28', '2026-07-28', CAIRO);

    expect(start.toISOString()).toBe('2026-07-27T21:00:00.000Z');
    expect(end.toISOString()).toBe('2026-07-28T20:59:59.999Z');
  });

  it('counts inclusive local days across a range', () => {
    const { start, end } = localDayBounds('2026-07-01', '2026-07-31', CAIRO);

    expect(localDayCount(start, end, CAIRO)).toBe(31);
    expect(localDayKeysBetween(start, end, CAIRO)).toHaveLength(31);
    expect(localDayKeysBetween(start, end, CAIRO)[0]).toBe('2026-07-01');
    expect(localDayKeysBetween(start, end, CAIRO)[30]).toBe('2026-07-31');
  });

  it('counts a single day as one, not zero', () => {
    const { start, end } = localDayBounds('2026-07-28', '2026-07-28', CAIRO);

    expect(localDayCount(start, end, CAIRO)).toBe(1);
  });

  it('falls back to UTC for a missing or bogus timezone', () => {
    expect(resolveTimezone(undefined)).toBe('UTC');
    expect(resolveTimezone(null)).toBe('UTC');
    expect(resolveTimezone('')).toBe('UTC');
    expect(resolveTimezone('Not/AZone')).toBe('UTC');
    expect(resolveTimezone(CAIRO)).toBe(CAIRO);
  });
});
