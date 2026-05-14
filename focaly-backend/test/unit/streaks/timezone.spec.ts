import { EventBus } from '@nestjs/cqrs';

import { AdvanceStreakHandler } from '../../../src/modules/streaks/handlers/advance-streak.handler';
import { StreaksRepository } from '../../../src/modules/streaks/streaks.repository';
import { UsersRepository } from '../../../src/modules/users/users.repository';
import { PomodoroCompletedEvent } from '../../../src/shared/events/pomodoro-completed.event';

describe('Streak advance - timezone math (SC-007)', () => {
  let handler: AdvanceStreakHandler;
  let streaksRepo: jest.Mocked<StreaksRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const mockUser = (timezone: string) => ({
    _id: 'user-1',
    id: 'user-1',
    email: 'test@test.com',
    name: 'Test',
    settings: { timezone, locale: 'en-US', focusMode: false, notifications: {} },
    plan: 'free' as const,
  });

  const mockRepo = (): void => {
    streaksRepo = {
      findOrCreate: jest.fn(),
      updateStreak: jest.fn(),
      findByUserId: jest.fn(),
      create: jest.fn(),
      resetStreak: jest.fn(),
      findAllWithLastActive: jest.fn(),
    } as unknown as jest.Mocked<StreaksRepository>;

    usersRepo = {
      findActiveById: jest.fn(),
    } as unknown as jest.Mocked<UsersRepository>;

    eventBus = { publish: jest.fn() } as unknown as jest.Mocked<EventBus>;

    handler = new AdvanceStreakHandler(streaksRepo, usersRepo, eventBus);
  };

  beforeEach(() => {
    mockRepo();
  });

  it('uses user timezone to compute lastActiveDate (Asia/Tokyo first)', async () => {
    usersRepo.findActiveById.mockResolvedValue(mockUser('Asia/Tokyo') as never);
    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 0,
      longest: 0,
      lastActiveDate: null,
      points: 0,
      rewards: [],
    } as never);
    streaksRepo.updateStreak.mockResolvedValue({
      userId: 'user-1',
      current: 1,
      longest: 1,
      lastActiveDate: expect.any(String),
      points: 0,
      rewards: [],
    } as never);

    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);
    await handler.handle(event);

    expect(streaksRepo.updateStreak).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ current: 1 }),
    );
  });

  it('cross-timezone: yesterday in user TZ but today in UTC still advances', async () => {
    usersRepo.findActiveById.mockResolvedValue(mockUser('Asia/Tokyo') as never);
    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 0,
      longest: 0,
      lastActiveDate: null,
      points: 0,
      rewards: [],
    } as never);
    streaksRepo.updateStreak.mockResolvedValue({
      userId: 'user-1',
      current: 1,
      longest: 1,
      lastActiveDate: expect.any(String),
      points: 0,
      rewards: [],
    } as never);

    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);
    await handler.handle(event);

    expect(usersRepo.findActiveById).toHaveBeenCalledWith('user-1');
    expect(streaksRepo.updateStreak).toHaveBeenCalled();
  });

  it('falls back to UTC when user has no timezone', async () => {
    usersRepo.findActiveById.mockResolvedValue({
      _id: 'user-1',
      id: 'user-1',
      email: 'test@test.com',
      name: 'Test',
      settings: {},
      plan: 'free',
    } as never);
    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 0,
      longest: 0,
      lastActiveDate: null,
      points: 0,
      rewards: [],
    } as never);
    streaksRepo.updateStreak.mockResolvedValue({
      userId: 'user-1',
      current: 1,
      longest: 1,
      lastActiveDate: expect.any(String),
      points: 0,
      rewards: [],
    } as never);

    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);
    await handler.handle(event);

    expect(streaksRepo.updateStreak).toHaveBeenCalled();
  });

  it('does not advance if lastActiveDate is already today in user TZ', async () => {
    const userTz = 'America/New_York';
    usersRepo.findActiveById.mockResolvedValue(mockUser(userTz) as never);

    const todayNY = new Date().toLocaleDateString('en-CA', { timeZone: userTz });

    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 5,
      longest: 5,
      lastActiveDate: todayNY,
      points: 100,
      rewards: [{ code: 'STREAK_3', awardedAt: new Date() }],
    } as never);

    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);
    await handler.handle(event);

    expect(streaksRepo.updateStreak).not.toHaveBeenCalled();
  });
});
