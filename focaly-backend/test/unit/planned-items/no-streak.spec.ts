import { EventBus } from '@nestjs/cqrs';

import { PlannedItemsRepository } from '../../../src/modules/planned-items/planned-items.repository';
import { PlannedItemsService } from '../../../src/modules/planned-items/planned-items.service';
import { UsersRepository } from '../../../src/modules/users/users.repository';

describe('PlannedItem complete - no streak advance (FR-024)', () => {
  let service: PlannedItemsService;
  let repo: jest.Mocked<PlannedItemsRepository>;
  let usersRepo: jest.Mocked<UsersRepository>;
  let eventBus: jest.Mocked<EventBus>;

  const mockItem = (overrides: Record<string, unknown> = {}) => ({
    _id: 'item-1',
    id: 'item-1',
    userId: 'user-1',
    kind: 'task',
    title: 'Test task',
    completed: false,
    completedAt: null,
    rewardPoints: 10,
    toString: () => 'item-1',
    ...overrides,
  });

  beforeEach(() => {
    repo = {
      findById: jest.fn(),
      updateById: jest.fn(),
      create: jest.fn(),
      findAllByUser: jest.fn(),
      softDelete: jest.fn(),
      hardDelete: jest.fn(),
    } as unknown as jest.Mocked<PlannedItemsRepository>;

    usersRepo = {
      updateOne: jest.fn(),
    } as unknown as jest.Mocked<UsersRepository>;

    eventBus = { publish: jest.fn() } as unknown as jest.Mocked<EventBus>;

    service = new PlannedItemsService(repo, usersRepo, eventBus);
  });

  it('completes a task and awards points without touching streak', async () => {
    repo.findById.mockResolvedValue(mockItem() as never);
    repo.updateById.mockResolvedValue(mockItem({ completed: true, completedAt: new Date() }) as never);

    await service.complete('user-1', 'task', 'item-1');

    expect(repo.findById).toHaveBeenCalledWith('item-1');
    expect(repo.updateById).toHaveBeenCalledWith(
      'item-1',
      expect.objectContaining({ $set: expect.objectContaining({ completed: true }) }),
    );
    expect(usersRepo.updateOne).toHaveBeenCalledWith(
      { _id: 'user-1' },
      { $inc: { totalPoints: 10 } },
    );
    expect(eventBus.publish).toHaveBeenCalledWith(
      expect.objectContaining({ rewardPoints: 10 }),
    );
  });

  it('does nothing if already completed', async () => {
    repo.findById.mockResolvedValue(mockItem({ completed: true }) as never);

    await service.complete('user-1', 'task', 'item-1');

    expect(repo.updateById).not.toHaveBeenCalled();
    expect(usersRepo.updateOne).not.toHaveBeenCalled();
    expect(eventBus.publish).not.toHaveBeenCalled();
  });

  it("does not call any streak service when completing a task", async () => {
    repo.findById.mockResolvedValue(mockItem() as never);
    repo.updateById.mockResolvedValue(mockItem({ completed: true }) as never);

    await service.complete('user-1', 'task', 'item-1');

    const publishCalls = (eventBus.publish as jest.Mock).mock.calls;
    const publishedEvents = publishCalls.map((c: unknown[]) => (c[0] as { constructor: { name: string } }).constructor.name);
    expect(publishedEvents).not.toContain(expect.stringMatching(/Streak/i));
  });
});
