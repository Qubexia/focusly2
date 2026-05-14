import { CqrsModule } from '@nestjs/cqrs';
import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';

import { ChaptersRepository } from '../../../src/modules/subjects/chapters.repository';
import { Chapter, ChapterSchema } from '../../../src/modules/subjects/schemas/chapter.schema';
import { Subject, SubjectSchema } from '../../../src/modules/subjects/schemas/subject.schema';
import { SubjectsRepository } from '../../../src/modules/subjects/subjects.repository';
import { SubjectsService } from '../../../src/modules/subjects/subjects.service';

describe('Subjects progress recompute (integration)', () => {
  let mongod: MongoMemoryServer;
  let subjectModel: Model<Subject>;
  let chapterModel: Model<Chapter>;
  let subjectsService: SubjectsService;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    subjectModel = mongoose.model(Subject.name, SubjectSchema);
    chapterModel = mongoose.model(Chapter.name, ChapterSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await subjectModel.deleteMany({});
    await chapterModel.deleteMany({});

    const module: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      providers: [
        SubjectsService,
        SubjectsRepository,
        ChaptersRepository,
        { provide: getModelToken(Subject.name), useValue: subjectModel },
        { provide: getModelToken(Chapter.name), useValue: chapterModel },
      ],
    }).compile();

    subjectsService = module.get(SubjectsService);
  });

  it('computes progressPercent correctly after chapter completion', async () => {
    const subject = await subjectModel.create({
      userId: 'user-1',
      name: 'Physics',
    });

    await chapterModel.create({ subjectId: subject.id, userId: 'user-1', title: 'Ch1', order: 1 });
    await chapterModel.create({ subjectId: subject.id, userId: 'user-1', title: 'Ch2', order: 2 });

    const chapters = await chapterModel.find({ subjectId: subject.id }).sort({ order: 1 });
    await chapterModel.findByIdAndUpdate(chapters[0]!.id, {
      $set: { completed: true, completedAt: new Date() },
    });

    const progress = await subjectsService.getProgress(subject.id);
    expect(progress.progressPercent).toBe(50);
    expect(progress.chaptersTotal).toBe(2);
    expect(progress.chaptersCompleted).toBe(1);
  });
});
