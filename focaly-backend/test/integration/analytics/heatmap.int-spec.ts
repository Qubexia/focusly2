import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import dayjs from 'dayjs';

import { AnalyticsRepository } from '../../../src/modules/analytics/analytics.repository';
import { AnalyticsDaily, AnalyticsDailySchema } from '../../../src/modules/analytics/schemas/analytics-daily.schema';
import { PomodoroSession, PomodoroSessionSchema } from '../../../src/modules/pomodoro/schemas/pomodoro-session.schema';

describe('Analytics heatmap from rollups', () => {
  let mongod: MongoMemoryServer;
  let analyticsModel: Model<AnalyticsDaily>;
  let repo: AnalyticsRepository;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    analyticsModel = mongoose.model(AnalyticsDaily.name, AnalyticsDailySchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await analyticsModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsRepository,
        { provide: getModelToken(AnalyticsDaily.name), useValue: analyticsModel },
        { provide: getModelToken(PomodoroSession.name), useValue: {} },
      ],
    }).compile();

    repo = module.get(AnalyticsRepository);
  });

  it('returns heatmap entries for the given year', async () => {
    const userId = new mongoose.Types.ObjectId().toString();
    const year = 2026;

    await analyticsModel.create({
      userId,
      date: dayjs().year(year).startOf('year').toDate(),
      focusMinutes: 50,
    });
    await analyticsModel.create({
      userId,
      date: dayjs().year(year).startOf('year').add(1, 'day').toDate(),
      focusMinutes: 75,
    });

    const heatmap = await repo.getHeatmap(userId, year);
    expect(heatmap.length).toBeGreaterThanOrEqual(2);
    expect(heatmap[0]!.focusMinutes).toBeDefined();
  });

  it('returns empty array when no data for the year', async () => {
    const heatmap = await repo.getHeatmap('nonexistent', 2025);
    expect(heatmap).toEqual([]);
  });
});
