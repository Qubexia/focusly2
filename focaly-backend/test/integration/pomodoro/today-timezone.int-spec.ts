import { CqrsModule } from '@nestjs/cqrs';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';

import { PomodoroRepository } from '../../../src/modules/pomodoro/pomodoro.repository';
import { PomodoroService } from '../../../src/modules/pomodoro/pomodoro.service';
import {
  PomodoroSession,
  PomodoroSessionSchema,
} from '../../../src/modules/pomodoro/schemas/pomodoro-session.schema';

describe('Pomodoro today timezone (integration)', () => {
  let mongod: MongoMemoryServer;
  let model: Model<PomodoroSession>;
  let service: PomodoroService;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    model = mongoose.model(PomodoroSession.name, PomodoroSessionSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await model.deleteMany({});

    const repo = new PomodoroRepository(model as never);
    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [PomodoroService, { provide: PomodoroRepository, useValue: repo }],
    }).compile();

    service = module.get(PomodoroService);
  });

  it('returns today sessions in user timezone', async () => {
    await model.create({
      userId: 'user-1',
      subjectId: 'subject-1',
      focusMinutes: 25,
      breakMinutes: 5,
      status: 'completed',
      startedAt: new Date('2026-05-14T08:00:00Z'),
      lastTickAt: new Date('2026-05-14T08:25:00Z'),
      totalFocusMinutes: 25,
      completedCycles: 1,
    });

    await model.create({
      userId: 'user-1',
      subjectId: 'subject-1',
      focusMinutes: 25,
      breakMinutes: 5,
      status: 'completed',
      startedAt: new Date('2026-05-14T09:00:00Z'),
      lastTickAt: new Date('2026-05-14T09:25:00Z'),
      totalFocusMinutes: 50,
      completedCycles: 2,
    });

    const result = await service.today('user-1');
    expect(result.sessions).toHaveLength(2);
    expect(result.totalFocusMinutes).toBe(75);
  });
});
