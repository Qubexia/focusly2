import { todayKey, yesterdayKey } from '../../../src/common/utils/day.util';
import { StreaksRepository } from '../../../src/modules/streaks/streaks.repository';
import { StreaksService } from '../../../src/modules/streaks/streaks.service';
import { UsersRepository } from '../../../src/modules/users/users.repository';

describe("Streak decays as soon as the user's own midnight passes", () => {
  const CAIRO = 'Africa/Cairo';
  let repo: jest.Mocked<StreaksRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let service: StreaksService;

  const streakDoc = (overrides: Record<string, unknown> = {}) => ({
    current: 5,
    longest: 9,
    lastActiveDate: todayKey(CAIRO),
    points: 150,
    rewards: [],
    ...overrides,
  });

  beforeEach(() => {
    repo = {
      findOrCreate: jest.fn(),
      resetStreak: jest.fn().mockResolvedValue(null),
    } as unknown as jest.Mocked<StreaksRepository>;

    usersRepo = {
      findActiveById: jest
        .fn()
        .mockResolvedValue({ settings: { timezone: CAIRO }, totalPoints: 40 }),
    } as unknown as jest.Mocked<UsersRepository>;

    service = new StreaksService(repo, usersRepo);
  });

  it('keeps the streak when the last active day is today', async () => {
    repo.findOrCreate.mockResolvedValue(streakDoc() as never);

    const result = await service.getStreak('user-1');

    expect(result.current).toBe(5);
    expect(repo.resetStreak).not.toHaveBeenCalled();
  });

  it('keeps the streak when the last active day is yesterday', async () => {
    repo.findOrCreate.mockResolvedValue(
      streakDoc({ lastActiveDate: yesterdayKey(CAIRO) }) as never,
    );

    const result = await service.getStreak('user-1');

    expect(result.current).toBe(5);
    expect(repo.resetStreak).not.toHaveBeenCalled();
  });

  it('reports zero — without waiting for the nightly cron — once a day was missed', async () => {
    repo.findOrCreate.mockResolvedValue(streakDoc({ lastActiveDate: '2026-01-01' }) as never);

    const result = await service.getStreak('user-1');

    expect(result.current).toBe(0);
    expect(repo.resetStreak).toHaveBeenCalledWith('user-1');
  });

  it('reports milestone points and task points as one wallet', async () => {
    repo.findOrCreate.mockResolvedValue(streakDoc() as never);

    const result = await service.getStreak('user-1');

    expect(result.points).toBe(190);
    expect(result.milestonePoints).toBe(150);
    expect(result.taskPoints).toBe(40);
  });
});
