import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import { CqrsModule } from '@nestjs/cqrs';

import { NotificationJobsRepository } from '../../../src/modules/notifications/notification-jobs.repository';
import { NotificationSchedulerService } from '../../../src/modules/notifications/notification-scheduler.service';
import {
  NotificationJob,
  NotificationJobSchema,
} from '../../../src/modules/notifications/schemas/notification-job.schema';

describe('Notification reminder lifecycle (integration)', () => {
  let mongod: MongoMemoryServer;
  let jobModel: Model<NotificationJob>;
  let scheduler: NotificationSchedulerService;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    jobModel = mongoose.model(NotificationJob.name, NotificationJobSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await jobModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [
        NotificationSchedulerService,
        NotificationJobsRepository,
        { provide: getModelToken(NotificationJob.name), useValue: jobModel },
      ],
    }).compile();

    scheduler = module.get(NotificationSchedulerService);
  });

  it('create schedule → pending notification_job at the right scheduledAt', async () => {
    const fireTime = new Date(Date.now() + 3600_000);
    await scheduler.scheduleScheduleReminder('user-1', 'schedule-1', fireTime);

    const jobs = await jobModel.find({ refType: 'study_schedule', refId: 'schedule-1' }).exec();
    expect(jobs).toHaveLength(1);
    expect(jobs[0]!.status).toBe('pending');
    expect(jobs[0]!.scheduledAt.getTime()).toBe(fireTime.getTime());
    expect(jobs[0]!.category).toBe('reminder');
  });

  it('cancel by ref → old job cancelled', async () => {
    const fireTime = new Date(Date.now() + 3600_000);
    await scheduler.scheduleScheduleReminder('user-1', 'schedule-1', fireTime);

    await scheduler.cancelByRef('study_schedule', 'schedule-1');

    const jobs = await jobModel.find({ refType: 'study_schedule', refId: 'schedule-1' }).exec();
    expect(jobs).toHaveLength(1);
    expect(jobs[0]!.status).toBe('cancelled');
  });

  it('planned item reminder scheduled correctly', async () => {
    const fireTime = new Date(Date.now() + 7200_000);
    await scheduler.schedulePlannedItemReminder('user-1', 'item-1', fireTime);

    const jobs = await jobModel.find({ refType: 'planned_item', refId: 'item-1' }).exec();
    expect(jobs).toHaveLength(1);
    expect(jobs[0]!.status).toBe('pending');
    expect(jobs[0]!.scheduledAt.getTime()).toBe(fireTime.getTime());
  });

  it('deleting item cancels its pending jobs', async () => {
    const fireTime = new Date(Date.now() + 3600_000);
    await scheduler.schedulePlannedItemReminder('user-1', 'item-1', fireTime);

    await scheduler.cancelByRef('planned_item', 'item-1');

    const jobs = await jobModel.find({ refType: 'planned_item', refId: 'item-1' }).exec();
    expect(jobs).toHaveLength(1);
    expect(jobs[0]!.status).toBe('cancelled');
  });
});
