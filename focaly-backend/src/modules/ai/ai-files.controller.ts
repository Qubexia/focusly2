import {
  BadRequestException,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes, ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { PremiumGuard } from '../../common/guards/premium.guard';

import { AiFilesService } from './ai-files.service';

const MAX_PDF_BYTES = 26_214_400; // 25 MB

/** Minimal shape of a Multer in-memory file (avoids needing @types/multer). */
interface UploadedPdf {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

@UseGuards(PremiumGuard)
@ApiTags('AI')
@Controller({ path: 'ai/files', version: '1' })
export class AiFilesController {
  constructor(private readonly aiFiles: AiFilesService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_PDF_BYTES } }))
  async upload(
    @CurrentUser() user: CurrentUserPayload,
    @UploadedFile() file?: UploadedPdf,
  ): Promise<{ fileId: string }> {
    if (!file) {
      throw new BadRequestException('No file was uploaded.');
    }
    if (file.mimetype !== 'application/pdf') {
      throw new BadRequestException('Only PDF files are supported.');
    }
    if (file.size > MAX_PDF_BYTES) {
      throw new BadRequestException('File too large (max 25 MB).');
    }

    const fileId = await this.aiFiles.store({
      userId: user.id,
      filename: file.originalname || 'document.pdf',
      contentType: file.mimetype,
      buffer: file.buffer,
    });

    return { fileId };
  }
}
