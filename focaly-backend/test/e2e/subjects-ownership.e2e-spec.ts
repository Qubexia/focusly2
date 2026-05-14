import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import { CqrsModule } from '@nestjs/cqrs';
import { getModelToken } from '@nestjs/mongoose';
import { Test, TestingModule } from '@nestjs/testing';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Model } from 'mongoose';
import supertest from 'supertest';

import { TransformInterceptor } from '../../src/common/interceptors/transform.interceptor';
import { ChaptersRepository } from '../../src/modules/subjects/chapters.repository';
import { ChaptersService } from '../../src/modules/subjects/chapters.service';
import { Chapter, ChapterSchema } from '../../src/modules/subjects/schemas/chapter.schema';
import { Subject, SubjectSchema } from '../../src/modules/subjects/schemas/subject.schema';
import { SubjectsController } from '../../src/modules/subjects/subjects.controller';
import { SubjectsRepository } from '../../src/modules/subjects/subjects.repository';
import { SubjectsService } from '../../src/modules/subjects/subjects.service';

describe('Subjects ownership (e2e)', () => {
  let app: INestApplication;
  let mongod: MongoMemoryServer;
  let subjectModel: Model<Subject>;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
    subjectModel = mongoose.model(Subject.name, SubjectSchema);
    mongoose.model(Chapter.name, ChapterSchema);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  beforeEach(async () => {
    await subjectModel.deleteMany({});

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [CqrsModule],
      controllers: [SubjectsController],
      providers: [
        SubjectsService,
        SubjectsRepository,
        ChaptersRepository,
        ChaptersService,
        { provide: getModelToken(Subject.name), useValue: subjectModel },
        { provide: getModelToken(Chapter.name), useValue: mongoose.model(Chapter.name) },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalInterceptors(new TransformInterceptor());
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('user A cannot read user B subject (404, not 403)', async () => {
    const subject = await subjectModel.create({
      userId: 'user-b',
      name: 'Secret Subject',
    });

    const res = await supertest(app.getHttpServer())
      .get(`/v1/subjects/${subject.id}`)
      .set('user-id', 'user-a');

    expect(res.status).toBe(404);
  });
});
