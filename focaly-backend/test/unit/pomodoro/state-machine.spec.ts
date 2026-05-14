import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { PomodoroRepository } from '../../../src/modules/pomodoro/pomodoro.repository';
import { PomodoroService } from '../../../src/modules/pomodoro/pomodoro.service';

describe('Pomodoro state machine', () => {
  let service: PomodoroService;
  let repo: jest.Mocked<PomodoroRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const mockSession = (
    overrides: Partial<{
      id: string;
      userId: string;
      subjectId: string | null;
      status: string;
      focusMinutes: number;
      breakMinutes: number;
      completedCycles: number;
      totalFocusMinutes: number;
      startedAt: Date;
      lastTickAt: Date;
    }> = {},
  ) => ({
    id: 'session-1',
    userId: 'user-1',
    subjectId: 'subject-1',
    status: 'active',
    focusMinutes: 25,
    breakMinutes: 5,
    completedCycles: 0,
    totalFocusMinutes: 0,
    startedAt: new Date(),
    lastTickAt: new Date(),
    ...overrides,
  });

  beforeEach(() => {
    repo = {
      create: jest.fn(),
      findActiveByUser: jest.fn(),
      findById: jest.fn(),
      updateStatus: jest.fn(),
      findTodayByUser: jest.fn(),
      findHistory: jest.fn(),
    } as unknown as jest.Mocked<PomodoroRepository>;

    eventBus = { publish: jest.fn() } as unknown as jest.Mocked<EventBus>;
    service = new PomodoroService(repo, eventBus);
  });

  describe('start', () => {
    it('creates a new active session when none is active', async () => {
      repo.findActiveByUser.mockResolvedValue(null);
      repo.create.mockResolvedValue(mockSession() as never);

      const result = await service.start('user-1', 'subject-1', 25, 5);
      expect(result).toBeDefined();
      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-1', status: 'active', focusMinutes: 25 }),
      );
    });

    it('rejects with POMODORO_ALREADY_ACTIVE when session exists', async () => {
      repo.findActiveByUser.mockResolvedValue(mockSession() as never);

      await expect(service.start('user-1', 'subject-1', 25, 5)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('pause', () => {
    it('pauses an active session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'active' }) as never);
      repo.updateStatus.mockResolvedValue(mockSession({ status: 'paused' }) as never);

      const result = await service.pause('user-1', 'session-1');
      expect(result).toBeDefined();
      expect(repo.updateStatus).toHaveBeenCalledWith('session-1', 'paused');
    });

    it('rejects pausing a paused session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'paused' }) as never);

      await expect(service.pause('user-1', 'session-1')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('resume', () => {
    it('resumes a paused session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'paused' }) as never);
      repo.updateStatus.mockResolvedValue(mockSession({ status: 'active' }) as never);

      const result = await service.resume('user-1', 'session-1');
      expect(result).toBeDefined();
      expect(repo.updateStatus).toHaveBeenCalledWith('session-1', 'active');
    });

    it('rejects resuming an already active session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'active' }) as never);

      await expect(service.resume('user-1', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('complete', () => {
    it('completes an active session and emits event', async () => {
      const session = mockSession({
        status: 'active',
        focusMinutes: 25,
        completedCycles: 0,
      });
      repo.findById.mockResolvedValue(session as never);
      repo.updateStatus.mockResolvedValue({
        ...session,
        status: 'completed',
        completedCycles: 1,
        totalFocusMinutes: 25,
      } as never);

      const result = await service.complete('user-1', 'session-1');
      expect(result).toBeDefined();
      expect(eventBus.publish).toHaveBeenCalledWith(
        expect.objectContaining({ focusMinutes: 25, completedCycles: 1, totalFocusMinutes: 25 }),
      );
    });

    it('rejects completing an already completed session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'completed' }) as never);

      await expect(service.complete('user-1', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects completing an aborted session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'aborted' }) as never);

      await expect(service.complete('user-1', 'session-1')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });

  describe('abort', () => {
    it('aborts an active session', async () => {
      repo.findById.mockResolvedValue(
        mockSession({ status: 'active', startedAt: new Date(Date.now() - 600_000) }) as never,
      );
      repo.updateStatus.mockResolvedValue(mockSession({ status: 'aborted' }) as never);

      const result = await service.abort('user-1', 'session-1');
      expect(result).toBeDefined();
    });

    it('rejects aborting an already aborted session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'aborted' }) as never);

      await expect(service.abort('user-1', 'session-1')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects aborting a completed session', async () => {
      repo.findById.mockResolvedValue(mockSession({ status: 'completed' }) as never);

      await expect(service.abort('user-1', 'session-1')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('ownership', () => {
    it("returns 404 for another user's session", async () => {
      repo.findById.mockResolvedValue(mockSession({ userId: 'user-2' }) as never);

      await expect(service.pause('user-1', 'session-1')).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
