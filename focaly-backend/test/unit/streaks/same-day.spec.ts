import { EventBus } from '@nestjs/cqrs';

import { AdvanceStreakHandler } from '../../../src/modules/streaks/handlers/advance-streak.handler';
import { StreaksRepository } from '../../../src/modules/streaks/streaks.repository';
import { UsersRepository } from '../../../src/modules/users/users.repository';
import { PomodoroCompletedEvent } from '../../../src/shared/events/pomodoro-completed.event';

describe('Streak advance - same-day dedup', () => {
  let handler: AdvanceStreakHandler;
  let streaksRepo: jest.Mocked<StreaksRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const today = new Date().toISOString().slice(0, 10);

  const mockUser = () => ({
    _id: 'user-1',
    id: 'user-1',
    email: 'test@test.com',
    name: 'Test',
    settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
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

  it('does NOT double-advance on second qualifying pomodoro same day', async () => {
    const event1 = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);
    const event2 = new PomodoroCompletedEvent('user-1', 'session-2', null, new Date(), 25, 1, 25);

    usersRepo.findActiveById.mockResolvedValue(mockUser() as never);
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
      lastActiveDate: today,
      points: 0,
      rewards: [],
    } as never);

    await handler.handle(event1);
    expect(streaksRepo.updateStreak).toHaveBeenCalledTimes(1);

    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 1,
      longest: 1,
      lastActiveDate: today,
      points: 0,
      rewards: [],
    } as never);

    await handler.handle(event2);
    expect(streaksRepo.updateStreak).toHaveBeenCalledTimes(1);
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it('advances again when the next day arrives', async () => {
    const event1 = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);

    usersRepo.findActiveById.mockResolvedValue(mockUser() as never);

    const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);

    streaksRepo.findOrCreate.mockResolvedValue({
      userId: 'user-1',
      current: 1,
      longest: 1,
      lastActiveDate: yesterday,
      points: 0,
      rewards: [],
    } as never);

    streaksRepo.updateStreak.mockResolvedValue({
      userId: 'user-1',
      current: 2,
      longest: 2,
      lastActiveDate: expect.any(String),
      points: 0,
      rewards: [],
    } as never);

    await handler.handle(event1);
    expect(streaksRepo.updateStreak).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ current: 2 }),
    );
  });
});
