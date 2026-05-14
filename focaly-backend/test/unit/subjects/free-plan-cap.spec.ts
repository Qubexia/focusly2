import { ForbiddenException } from '@nestjs/common';
import { EventBus } from '@nestjs/cqrs';

import { ChaptersRepository } from '../../../src/modules/subjects/chapters.repository';
import { SubjectsRepository } from '../../../src/modules/subjects/subjects.repository';
import {
  FREE_PLAN_MAX_ACTIVE,
  SubjectsService,
} from '../../../src/modules/subjects/subjects.service';

describe('SubjectsService free-plan cap (FR-012)', () => {
  let service: SubjectsService;
  let subjectsRepo: jest.Mocked<SubjectsRepository>;

  beforeEach(() => {
    subjectsRepo = {
      create: jest.fn(),
      countActiveByUser: jest.fn(),
      findActiveById: jest.fn(),
      findAllByUser: jest.fn(),
      updateById: jest.fn(),
      softDelete: jest.fn(),
    } as unknown as jest.Mocked<SubjectsRepository>;

    const chaptersRepo = {} as jest.Mocked<ChaptersRepository>;
    const eventBus = { publish: jest.fn() } as unknown as EventBus;

    service = new SubjectsService(subjectsRepo, chaptersRepo, eventBus);
  });

  it('allows a free user to create up to the cap', async () => {
    subjectsRepo.countActiveByUser.mockResolvedValue(FREE_PLAN_MAX_ACTIVE - 1);
    subjectsRepo.create.mockResolvedValue({} as never);

    await expect(service.create('user-1', 'free', { name: 'Physics' })).resolves.toBeDefined();
  });

  it('rejects creation when free user exceeds the cap', async () => {
    subjectsRepo.countActiveByUser.mockResolvedValue(FREE_PLAN_MAX_ACTIVE);

    await expect(service.create('user-1', 'free', { name: 'Physics' })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('allows premium user to bypass cap', async () => {
    subjectsRepo.create.mockResolvedValue({} as never);

    await expect(service.create('user-1', 'premium', { name: 'Physics' })).resolves.toBeDefined();

    expect(subjectsRepo.countActiveByUser.mock.calls).toHaveLength(0);
  });

  it('rejects un-archive when free user would exceed cap', async () => {
    subjectsRepo.countActiveByUser.mockResolvedValue(FREE_PLAN_MAX_ACTIVE);
    subjectsRepo.findActiveById.mockResolvedValue({
      isArchived: true,
      _id: 'subject-1',
    } as never);

    await expect(
      service.update('user-1', 'free', 'subject-1', { isArchived: false }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
