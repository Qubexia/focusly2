import { CqrsModule, EventBus } from '@nestjs/cqrs';
import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

import { AdvanceStreakHandler } from '../../../src/modules/streaks/handlers/advance-streak.handler';
import { Streak, StreakSchema } from '../../../src/modules/streaks/schemas/streak.schema';
import { StreaksRepository } from '../../../src/modules/streaks/streaks.repository';
import { StreaksService } from '../../../src/modules/streaks/streaks.service';
import { PomodoroCompletedEvent } from '../../../src/shared/events/pomodoro-completed.event';
import { User, UserSchema } from '../../../src/modules/users/schemas/user.schema';
import { UsersRepository } from '../../../src/modules/users/users.repository';

dayjs.extend(utc);
dayjs.extend(timezone);

describe('Streaks reward thresholds (integration)', () => {
  let mongod: MongoMemoryServer;
  let streakModel: Model<Streak>;
  let userModel: Model<User>;
  let handler: AdvanceStreakHandler;
  let eventBus: EventBus;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    streakModel = mongoose.model(Streak.name, StreakSchema);
    userModel = mongoose.model(User.name, UserSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await streakModel.deleteMany({});
    await userModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [
        StreaksService,
        StreaksRepository,
        UsersRepository,
        AdvanceStreakHandler,
        { provide: getModelToken(Streak.name), useValue: streakModel },
        { provide: getModelToken(User.name), useValue: userModel },
      ],
    }).compile();

    handler = module.get(AdvanceStreakHandler);
    eventBus = module.get(EventBus);
  });

  it('unlocks STREAK_3 after 3 consecutive qualifying days', async () => {
    const user = await userModel.create({
      email: 'test@test.com',
      name: 'Test',
      settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
    });

    const twoDaysAgo = dayjs().tz('UTC').subtract(2, 'day').format('YYYY-MM-DD');
    const yesterday = dayjs().tz('UTC').subtract(1, 'day').format('YYYY-MM-DD');

    await streakModel.create({
      userId: user.id,
      current: 2,
      longest: 2,
      lastActiveDate: yesterday,
      points: 0,
      rewards: [],
    });

    const publishSpy = jest.spyOn(eventBus, 'publish');

    const event = new PomodoroCompletedEvent(
      user.id,
      'session-1',
      null,
      new Date(),
      25,
      1,
      25,
    );

    await handler.handle(event);

    const updated = await streakModel.findOne({ userId: user.id }).exec();
    expect(updated).toBeDefined();
    expect(updated!.current).toBe(3);
    expect(updated!.longest).toBe(3);

    const rewardCodes = (updated!.rewards || []).map((r) => r.code);
    expect(rewardCodes).toContain('STREAK_3');

    expect(publishSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'STREAK_3',
        userId: user.id,
      }),
    );
  });

  it('does not award STREAK_3 again if already earned', async () => {
    const user = await userModel.create({
      email: 'test2@test.com',
      name: 'Test2',
      settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
    });

    const yesterday = dayjs().tz('UTC').subtract(1, 'day').format('YYYY-MM-DD');

    await streakModel.create({
      userId: user.id,
      current: 3,
      longest: 3,
      lastActiveDate: yesterday,
      points: 50,
      rewards: [{ code: 'STREAK_3', awardedAt: new Date() }],
    });

    const publishSpy = jest.spyOn(eventBus, 'publish');

    const event = new PomodoroCompletedEvent(
      user.id,
      'session-2',
      null,
      new Date(),
      25,
      1,
      25,
    );

    await handler.handle(event);

    const updated = await streakModel.findOne({ userId: user.id }).exec();
    expect(updated!.current).toBe(4);
    expect(updated!.longest).toBe(4);
    expect(updated!.rewards.length).toBe(1);
    expect(publishSpy).not.toHaveBeenCalled();
  });
});
