import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PresignDto } from './dto';

const MIME_ALLOWLIST = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
  'application/pdf',
];
const KIND_LIMITS: Record<string, number> = {
  'lecture-image': 10_485_760,
  'ai-notes-image': 10_485_760,
  'subject-pdf': 26_214_400, // 25 MB
  'chapter-pdf': 26_214_400, // 25 MB
  avatar: 2_097_152,
};

@Injectable()
export class UploadsService {
  private readonly s3: S3Client;
  private readonly bucket: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.getOrThrow<string>('s3.bucket');
    this.s3 = new S3Client({
      region: this.config.getOrThrow<string>('s3.region'),
      endpoint: this.config.get<string>('s3.endpoint') || undefined,
      credentials: {
        accessKeyId: this.config.getOrThrow<string>('s3.accessKeyId'),
        secretAccessKey: this.config.getOrThrow<string>('s3.secretAccessKey'),
      },
    });
  }

  async presignPut(userId: string, dto: PresignDto): Promise<{ url: string; key: string }> {
    if (!MIME_ALLOWLIST.includes(dto.mimeType)) {
      throw new BadRequestException(`Unsupported mime type: ${dto.mimeType}`);
    }

    const maxSize = KIND_LIMITS[dto.kind] ?? KIND_LIMITS['lecture-image']!;
    if (dto.sizeBytes > maxSize) {
      throw new BadRequestException(`File too large for kind "${dto.kind}": max ${maxSize} bytes`);
    }

    const key = `uploads/${userId}/${dto.kind}/${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: dto.mimeType,
      ContentLength: dto.sizeBytes,
    });

    const url = await getSignedUrl(this.s3, command, { expiresIn: 3600 });

    return { url, key };
  }

  /** Marks an upload as complete. Scoped to the owner so it can never be
   * used to touch another account's object once it does real work. */
  confirmUpload(userId: string, key: string): Promise<void> {
    if (!key.startsWith(`uploads/${userId}/`)) {
      throw new ForbiddenException('This upload key does not belong to you.');
    }

    return Promise.resolve();
  }
}
