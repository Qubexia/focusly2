import { ForbiddenException, Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import mongoose, { Connection } from 'mongoose';

const BUCKET_NAME = 'ai_files';

/**
 * Stores AI source files (PDFs) directly in MongoDB via GridFS so the async
 * worker can read them back without any external object storage (no AWS/S3).
 */
@Injectable()
export class AiFilesService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  private bucket(): mongoose.mongo.GridFSBucket {
    const db = this.connection.db;
    if (!db) {
      throw new Error('Database connection is not ready.');
    }
    return new mongoose.mongo.GridFSBucket(db, { bucketName: BUCKET_NAME });
  }

  /** Persists a buffer and resolves to the stored file id (as a string). */
  store(args: {
    userId: string;
    filename: string;
    contentType: string;
    buffer: Buffer;
  }): Promise<string> {
    const bucket = this.bucket();
    return new Promise((resolve, reject) => {
      const upload = bucket.openUploadStream(args.filename, {
        contentType: args.contentType,
        metadata: { userId: args.userId },
      });
      upload.on('error', reject);
      upload.on('finish', () => resolve(upload.id.toString()));
      upload.end(args.buffer);
    });
  }

  /** True when `fileId` exists and was uploaded by `userId`. */
  async isOwnedBy(fileId: string, userId: string): Promise<boolean> {
    if (!mongoose.isValidObjectId(fileId)) {
      return false;
    }

    const [file] = await this.bucket()
      .find({ _id: new mongoose.mongo.ObjectId(fileId) }, { limit: 1 })
      .toArray();

    return file?.metadata?.userId === userId;
  }

  /**
   * Reads a stored file back into memory. Callers must pass the owning user so
   * one account can never read another account's uploads by guessing an id.
   */
  async read(fileId: string, userId: string): Promise<Buffer> {
    if (!(await this.isOwnedBy(fileId, userId))) {
      throw new ForbiddenException({ message: 'File not found for this user.' });
    }

    const bucket = this.bucket();
    const objectId = new mongoose.mongo.ObjectId(fileId);
    return new Promise((resolve, reject) => {
      const chunks: Buffer[] = [];
      bucket
        .openDownloadStream(objectId)
        .on('data', (chunk: Buffer) => chunks.push(chunk))
        .on('error', reject)
        .on('end', () => resolve(Buffer.concat(chunks)));
    });
  }
}
