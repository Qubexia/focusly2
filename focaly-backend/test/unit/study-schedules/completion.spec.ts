import { NotFoundException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { StudySchedulesRepository } from '../../../src/modules/study-schedules/study-schedules.repository';
import { StudySchedulesService } from '../../../src/modules/study-schedules/study-schedules.service';

describe('StudySchedulesService completions', () => {
  let service: StudySchedulesService;
  let repo: jest.Mocked<StudySchedulesRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const ownedSchedule = { _id: 'sched-1', userId: { toString: () => 'user-1' } };

  beforeEach(() => {
    repo = {
      findById: jest.fn(),
      upsertCompletion: jest.fn(),
      findCompletionsByUserInRange: jest.fn(),
      deleteCompletionsBySchedule: jest.fn(),
    } as unknown as jest.Mocked<StudySchedulesRepository>;
    eventBus = { publish: jest.fn() } as unknown as jest.Mocked<EventBus>;
    service = new StudySchedulesService(repo, eventBus);
  });

  describe('complete', () => {
    it('upserts a completion for an owned schedule', async () => {
      repo.findById.mockResolvedValue(ownedSchedule as never);
      repo.upsertCompletion.mockResolvedValue({} as never);

      const result = await service.complete('user-1', 'sched-1', '2026-06-20');

      expect(repo.upsertCompletion).toHaveBeenCalledWith('user-1', 'sched-1', '2026-06-20');
      expect(result).toEqual({ scheduleId: 'sched-1', date: '2026-06-20' });
    });

    it("rejects completing another user's schedule", async () => {
      repo.findById.mockResolvedValue({
        _id: 'sched-1',
        userId: { toString: () => 'user-2' },
      } as never);

      await expect(service.complete('user-1', 'sched-1', '2026-06-20')).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(repo.upsertCompletion).not.toHaveBeenCalled();
    });
  });

  describe('listCompletions', () => {
    it('maps completion documents to {scheduleId, date}', async () => {
      repo.findCompletionsByUserInRange.mockResolvedValue([
        { scheduleId: 'sched-1', date: '2026-06-20' },
        { scheduleId: 'sched-2', date: '2026-06-21' },
      ] as never);

      const result = await service.listCompletions('user-1', '2026-06-14', '2026-06-28');

      expect(result).toEqual([
        { scheduleId: 'sched-1', date: '2026-06-20' },
        { scheduleId: 'sched-2', date: '2026-06-21' },
      ]);
    });
  });
});
