import { EventBus } from '@nestjs/cqrs';

import { AdvanceStreakHandler } from '../../../src/modules/streaks/handlers/advance-streak.handler';
import { StreaksRepository } from '../../../src/modules/streaks/streaks.repository';
import { UsersRepository } from '../../../src/modules/users/users.repository';
import { PomodoroCompletedEvent } from '../../../src/shared/events/pomodoro-completed.event';

describe('Streak advance - min duration (RD-3)', () => {
  let handler: AdvanceStreakHandler;
  let streaksRepo: jest.Mocked<StreaksRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const mockUser = (overrides: Record<string, unknown> = {}) => ({
    _id: 'user-1',
    id: 'user-1',
    email: 'test@test.com',
    name: 'Test',
    settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
    plan: 'free' as const,
    ...overrides,
  });

  const mockRepo = () => {
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

  it('does NOT advance streak when focusMinutes < 10', async () => {
    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 5, 1, 5);

    await handler.handle(event);

    expect(streaksRepo.findOrCreate).not.toHaveBeenCalled();
    expect(streaksRepo.updateStreak).not.toHaveBeenCalled();
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it('does NOT advance streak when completedCycles is 0', async () => {
    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 0, 0);

    await handler.handle(event);

    expect(streaksRepo.findOrCreate).not.toHaveBeenCalled();
    expect(streaksRepo.updateStreak).not.toHaveBeenCalled();
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it('advances streak on qualifying pomodoro (focusMinutes >= 10, cycles >= 1)', async () => {
    const event = new PomodoroCompletedEvent('user-1', 'session-1', null, new Date(), 25, 1, 25);

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
      lastActiveDate: expect.any(String),
      points: 0,
      rewards: [],
    } as never);

    await handler.handle(event);

    expect(streaksRepo.findOrCreate).toHaveBeenCalledWith('user-1');
    expect(streaksRepo.updateStreak).toHaveBeenCalled();
  });
});
