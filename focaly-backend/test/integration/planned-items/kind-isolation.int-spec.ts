import { CqrsModule, EventBus } from '@nestjs/cqrs';
import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';

import { PlannedItemsRepository } from '../../../src/modules/planned-items/planned-items.repository';
import { PlannedItemsService } from '../../../src/modules/planned-items/planned-items.service';
import {
  PlannedItem,
  PlannedItemSchema,
} from '../../../src/modules/planned-items/schemas/planned-item.schema';
import { UsersRepository } from '../../../src/modules/users/users.repository';
import { User, UserSchema } from '../../../src/modules/users/schemas/user.schema';

describe('PlannedItem kind isolation (integration)', () => {
  let mongod: MongoMemoryServer;
  let itemModel: Model<PlannedItem>;
  let userModel: Model<User>;
  let service: PlannedItemsService;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    itemModel = mongoose.model(PlannedItem.name, PlannedItemSchema);
    userModel = mongoose.model(User.name, UserSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await itemModel.deleteMany({});
    await userModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [
        PlannedItemsService,
        PlannedItemsRepository,
        UsersRepository,
        { provide: getModelToken(PlannedItem.name), useValue: itemModel },
        { provide: getModelToken(User.name), useValue: userModel },
      ],
    }).compile();

    service = module.get(PlannedItemsService);
  });

  it('GET /tasks never returns kind=exam rows', async () => {
    const user = await userModel.create({
      email: 'test@test.com',
      name: 'Test',
      settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
    });

    await itemModel.create({
      userId: user.id,
      kind: 'task',
      title: 'Task 1',
      plannedAt: new Date(),
    });
    await itemModel.create({
      userId: user.id,
      kind: 'exam',
      title: 'Exam 1',
      plannedAt: new Date(),
    });
    await itemModel.create({
      userId: user.id,
      kind: 'task',
      title: 'Task 2',
      plannedAt: new Date(),
    });

    const tasks = await service.findAll(user.id, 'task');
    expect(tasks).toHaveLength(2);
    for (const t of tasks) {
      expect(t.kind).toBe('task');
    }
  });

  it('findByKind returns only matching items for each kind', async () => {
    const user = await userModel.create({
      email: 'test2@test.com',
      name: 'Test2',
      settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: {} },
    });

    await itemModel.create({ userId: user.id, kind: 'task', title: 'T1', plannedAt: new Date() });
    await itemModel.create({
      userId: user.id,
      kind: 'revision',
      title: 'R1',
      plannedAt: new Date(),
    });
    await itemModel.create({
      userId: user.id,
      kind: 'lecture',
      title: 'L1',
      plannedAt: new Date(),
    });
    await itemModel.create({ userId: user.id, kind: 'exam', title: 'E1', plannedAt: new Date() });

    const tasks = await service.findAll(user.id, 'task');
    const revisions = await service.findAll(user.id, 'revision');
    const lectures = await service.findAll(user.id, 'lecture');
    const exams = await service.findAll(user.id, 'exam');

    expect(tasks).toHaveLength(1);
    expect(tasks[0]!.kind).toBe('task');
    expect(revisions).toHaveLength(1);
    expect(revisions[0]!.kind).toBe('revision');
    expect(lectures).toHaveLength(1);
    expect(lectures[0]!.kind).toBe('lecture');
    expect(exams).toHaveLength(1);
    expect(exams[0]!.kind).toBe('exam');
  });
});
