import { ForbiddenException, NotFoundException } from '@nestjs/common';

import type { CurrentUserPayload } from '../../../src/common/decorators/current-user.decorator';
import { AiArtifactsRepository } from '../../../src/modules/ai/ai-artifacts.repository';
import { AiFilesService } from '../../../src/modules/ai/ai-files.service';
import { AiJobsRepository } from '../../../src/modules/ai/ai-jobs.repository';
import { AiRateLimiterService } from '../../../src/modules/ai/ai-rate-limiter.service';
import { AiSettingsService } from '../../../src/modules/ai/ai-settings.service';
import { AiWorkerService } from '../../../src/modules/ai/ai-worker.service';
import { AiController } from '../../../src/modules/ai/ai.controller';

const OWNER = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const ATTACKER = 'bbbbbbbbbbbbbbbbbbbbbbbb';

const user = (id: string): CurrentUserPayload =>
  ({ id, email: 'x@example.com', role: 'user' }) as CurrentUserPayload;

describe('AI job ownership', () => {
  let jobsRepo: { findByIdAndUser: jest.Mock; create: jest.Mock };
  let filesService: { isOwnedBy: jest.Mock };
  let controller: AiController;

  beforeEach(() => {
    // Mirrors a userId-scoped query: only the owner ever gets the document.
    jobsRepo = {
      findByIdAndUser: jest.fn((id: string, userId: string) =>
        Promise.resolve(userId === OWNER ? { _id: id, userId: OWNER } : null),
      ),
      create: jest.fn(() => Promise.resolve({ _id: 'job-1' })),
    };
    filesService = {
      isOwnedBy: jest.fn((_fileId: string, userId: string) => Promise.resolve(userId === OWNER)),
    };

    controller = new AiController(
      jobsRepo as unknown as AiJobsRepository,
      {} as AiArtifactsRepository,
      {
        check: jest.fn(() => Promise.resolve({ allowed: true })),
        increment: jest.fn(() => Promise.resolve(undefined)),
      } as unknown as AiRateLimiterService,
      { enqueueJob: jest.fn(() => Promise.resolve(undefined)) } as unknown as AiWorkerService,
      {
        resolve: jest.fn(() => Promise.resolve({ enabled: true, apiKey: 'sk-test' })),
      } as unknown as AiSettingsService,
      filesService as unknown as AiFilesService,
    );
  });

  it("does not return another user's job", async () => {
    await expect(controller.getJob(user(ATTACKER), 'job-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it("returns the owner's own job", async () => {
    await expect(controller.getJob(user(OWNER), 'job-1')).resolves.toMatchObject({ userId: OWNER });
  });

  it("refuses a job that references another user's S3 image key", async () => {
    await expect(
      controller.submitJob(user(ATTACKER), {
        subjectId: 'subject-1',
        imageKeys: [`uploads/${OWNER}/ai-notes-image/secret.png`],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(jobsRepo.create).not.toHaveBeenCalled();
  });

  it("refuses a job that references another user's uploaded PDF", async () => {
    await expect(
      controller.submitJob(user(ATTACKER), {
        subjectId: 'subject-1',
        pdfKeys: ['64b7f0c2c1a2b3d4e5f60718'],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(jobsRepo.create).not.toHaveBeenCalled();
  });

  it('accepts a job that only references the caller own files', async () => {
    await controller.submitJob(user(OWNER), {
      subjectId: 'subject-1',
      imageKeys: [`uploads/${OWNER}/ai-notes-image/mine.png`],
      pdfKeys: ['64b7f0c2c1a2b3d4e5f60718'],
    });

    expect(jobsRepo.create).toHaveBeenCalledTimes(1);
  });
});
