import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';

import { NotificationsRepository } from '../../../src/modules/notifications/notifications.repository';
import {
  Notification,
  NotificationSchema,
} from '../../../src/modules/notifications/schemas/notification.schema';

describe('Notification inbox (integration)', () => {
  let mongod: MongoMemoryServer;
  let notifModel: Model<Notification>;
  let repo: NotificationsRepository;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    notifModel = mongoose.model(Notification.name, NotificationSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await notifModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsRepository,
        { provide: getModelToken(Notification.name), useValue: notifModel },
      ],
    }).compile();

    repo = module.get(NotificationsRepository);
  });

  it('writes inbox row and marks it read', async () => {
    const notif = await repo.create({
      userId: 'user-1',
      type: 'reminder',
      title: 'Test reminder',
      body: 'This is a test',
    });

    expect(notif.userId.toString()).toBe('user-1');
    expect(notif.type).toBe('reminder');
    expect(notif.read).toBe(false);

    await repo.markRead(notif.id);

    const updated = await repo.findById(notif.id);
    expect(updated!.read).toBe(true);
  });

  it('marks all as read for a user', async () => {
    await repo.create({ userId: 'user-1', type: 'reminder', title: 'A' });
    await repo.create({ userId: 'user-1', type: 'reminder', title: 'B' });

    await repo.markAllRead('user-1');

    const all = await repo.findAllByUser('user-1');
    for (const n of all) {
      expect(n.read).toBe(true);
    }
  });

  it('paginates inbox with cursor', async () => {
    for (let i = 0; i < 5; i++) {
      await repo.create({ userId: 'user-1', type: 'system', title: `Notification ${i}` });
    }

    const page1 = await repo.findAllByUser('user-1', 2);
    expect(page1).toHaveLength(2);

    const page2 = await repo.findAllByUser('user-1', 2, page1[page1.length - 1]!.id);
    expect(page2).toHaveLength(2);
    expect(page2[0]!.id).not.toBe(page1[0]!.id);
  });
});
