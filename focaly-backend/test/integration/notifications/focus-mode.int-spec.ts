import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import { getQueueToken } from '@nestjs/bullmq';

import { NotificationEnqueueService } from '../../../src/modules/notifications/notification-enqueue.service';
import { NotificationJobsRepository } from '../../../src/modules/notifications/notification-jobs.repository';
import { NotificationsRepository } from '../../../src/modules/notifications/notifications.repository';
import {
  NotificationJob,
  NotificationJobSchema,
} from '../../../src/modules/notifications/schemas/notification-job.schema';
import {
  Notification,
  NotificationSchema,
} from '../../../src/modules/notifications/schemas/notification.schema';

describe('Notification enqueue (integration)', () => {
  let mongod: MongoMemoryServer;
  let jobModel: Model<NotificationJob>;
  let notifModel: Model<Notification>;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    jobModel = mongoose.model(NotificationJob.name, NotificationJobSchema);
    notifModel = mongoose.model(Notification.name, NotificationSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await jobModel.deleteMany({});
    await notifModel.deleteMany({});
  });

  it('picks up pending jobs within the enqueue window', async () => {
    const inWindow = new Date(Date.now() + 5 * 60 * 1000);
    const tooLate = new Date(Date.now() + 30 * 60 * 1000);

    await jobModel.create({
      userId: 'user-1',
      refType: 'study_schedule',
      refId: 'sched-1',
      category: 'reminder',
      scheduledAt: inWindow,
      status: 'pending',
    });
    await jobModel.create({
      userId: 'user-1',
      refType: 'study_schedule',
      refId: 'sched-2',
      category: 'reminder',
      scheduledAt: tooLate,
      status: 'pending',
    });

    const queueMock = { add: jest.fn() };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationEnqueueService,
        NotificationJobsRepository,
        NotificationsRepository,
        { provide: getModelToken(NotificationJob.name), useValue: jobModel },
        { provide: getModelToken(Notification.name), useValue: notifModel },
        { provide: getQueueToken('notifications'), useValue: queueMock },
      ],
    }).compile();

    const service = module.get(NotificationEnqueueService);
    await service.enqueuePendingJobs();

    const stillPending = await jobModel.find({ status: 'pending' }).exec();
    expect(stillPending).toHaveLength(1);
    expect(stillPending[0]!.refId).toBe('sched-2');
  });
});
