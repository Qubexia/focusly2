import { FCM_CLIENT, FcmSendResult } from '../../../src/infrastructure/fcm/fcm.tokens';
import { AuthSessionsRepository } from '../../../src/modules/auth/auth-sessions.repository';
import { NotificationsWorker } from '../../../src/modules/notifications/workers/notifications.worker';
import { NotificationJobsRepository } from '../../../src/modules/notifications/notification-jobs.repository';
import { NotificationsRepository } from '../../../src/modules/notifications/notifications.repository';
import { UsersRepository } from '../../../src/modules/users/users.repository';
import { PomodoroRepository } from '../../../src/modules/pomodoro/pomodoro.repository';

describe('NotificationsWorker - invalid token handling (FR-031)', () => {
  let worker: NotificationsWorker;
  let fcmClient: { send: jest.Mock };
  let authSessionsRepo: jest.Mocked<AuthSessionsRepository>;
  let jobsRepo: jest.Mocked<NotificationJobsRepository>;
  let notifRepo: jest.Mocked<NotificationsRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let pomodoroRepo: jest.Mocked<PomodoroRepository>;

  const mockUser = (overrides: Record<string, unknown> = {}) => ({
    _id: 'user-1',
    id: 'user-1',
    settings: { timezone: 'UTC', locale: 'en-US', focusMode: false, notifications: { reminders: true, streak: true, marketing: false } },
    plan: 'free',
    ...overrides,
  });

  const mockSession = (overrides: Record<string, unknown> = {}) => ({
    id: 'session-1',
    fcmToken: 'valid-token-1',
    ...overrides,
  });

  beforeEach(() => {
    fcmClient = { send: jest.fn() };

    authSessionsRepo = {
      findActiveByUserId: jest.fn(),
      setFcmToken: jest.fn(),
    } as unknown as jest.Mocked<AuthSessionsRepository>;

    jobsRepo = {
      markSent: jest.fn(),
      markFailed: jest.fn(),
    } as unknown as jest.Mocked<NotificationJobsRepository>;

    notifRepo = {
      create: jest.fn(),
    } as unknown as jest.Mocked<NotificationsRepository>;

    usersRepo = {
      findActiveById: jest.fn(),
    } as unknown as jest.Mocked<UsersRepository>;

    pomodoroRepo = {
      findActiveByUser: jest.fn(),
    } as unknown as jest.Mocked<PomodoroRepository>;

    worker = new NotificationsWorker(
      fcmClient as any,
      authSessionsRepo as any,
      usersRepo as any,
      pomodoroRepo as any,
      notifRepo as any,
      jobsRepo as any,
    );
  });

  it('clears permanently invalid token', async () => {
    const result: FcmSendResult = {
      successCount: 0,
      failureTokens: [
        { token: 'bad-token', permanent: true, reason: 'messaging/registration-token-not-registered' },
      ],
    };
    fcmClient.send.mockResolvedValue(result);
    usersRepo.findActiveById.mockResolvedValue(mockUser() as never);
    authSessionsRepo.findActiveByUserId.mockResolvedValue([
      mockSession({ id: 'session-1', fcmToken: 'bad-token' }) as never,
    ]);
    pomodoroRepo.findActiveByUser.mockResolvedValue(null);

    await worker.process({
      data: { jobId: 'job-1', userId: 'user-1', title: 'Test', body: 'Body', category: 'reminder' },
    } as any);

    expect(authSessionsRepo.setFcmToken).toHaveBeenCalledWith('session-1', null);
    expect(jobsRepo.markSent).toHaveBeenCalledWith('job-1');
  });

  it('does not clear non-permanent token failures', async () => {
    const result: FcmSendResult = {
      successCount: 0,
      failureTokens: [
        { token: 'temp-fail-token', permanent: false, reason: 'messaging/device-message-rate-exceeded' },
      ],
    };
    fcmClient.send.mockResolvedValue(result);
    usersRepo.findActiveById.mockResolvedValue(mockUser() as never);
    authSessionsRepo.findActiveByUserId.mockResolvedValue([
      mockSession({ id: 'session-2', fcmToken: 'temp-fail-token' }) as never,
    ]);
    pomodoroRepo.findActiveByUser.mockResolvedValue(null);

    await worker.process({
      data: { jobId: 'job-2', userId: 'user-1', title: 'Test', body: 'Body', category: 'reminder' },
    } as any);

    expect(authSessionsRepo.setFcmToken).not.toHaveBeenCalled();
    expect(jobsRepo.markSent).toHaveBeenCalledWith('job-2');
  });
});
