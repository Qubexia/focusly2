import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import dayjs from 'dayjs';

import { AnalyticsRepository } from '../../../src/modules/analytics/analytics.repository';
import { AnalyticsDaily, AnalyticsDailySchema } from '../../../src/modules/analytics/schemas/analytics-daily.schema';
import { PomodoroSession, PomodoroSessionSchema } from '../../../src/modules/pomodoro/schemas/pomodoro-session.schema';

describe('Analytics reconciliation', () => {
  let mongod: MongoMemoryServer;
  let analyticsModel: Model<AnalyticsDaily>;
  let pomodoroModel: Model<PomodoroSession>;
  let repo: AnalyticsRepository;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    analyticsModel = mongoose.model(AnalyticsDaily.name, AnalyticsDailySchema);
    pomodoroModel = mongoose.model(PomodoroSession.name, PomodoroSessionSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await analyticsModel.deleteMany({});
    await pomodoroModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsRepository,
        { provide: getModelToken(AnalyticsDaily.name), useValue: analyticsModel },
        { provide: getModelToken(PomodoroSession.name), useValue: pomodoroModel },
      ],
    }).compile();

    repo = module.get(AnalyticsRepository);
  });

  it('rollup data matches pomodoro totalFocusMinutes', async () => {
    const today = dayjs().startOf('day').toDate();
    const userId = new mongoose.Types.ObjectId().toString();

    await analyticsModel.create({
      userId,
      date: today,
      focusMinutes: 75,
      completedCycles: 3,
      sessionsCount: 1,
    });

    const summary = await repo.getSummary(userId, dayjs().subtract(1, 'day').toDate(), dayjs().add(1, 'day').toDate());
    expect(summary.totalFocusMinutes).toBe(75);
    expect(summary.totalSessions).toBe(1);
  });

  it('returns zeros when no data exists for range', async () => {
    const summary = await repo.getSummary('nonexistent', new Date('2020-01-01'), new Date('2020-01-31'));
    expect(summary.totalFocusMinutes).toBe(0);
    expect(summary.totalSessions).toBe(0);
  });
});
