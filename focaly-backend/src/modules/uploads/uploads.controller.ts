import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';

import { ConfirmUploadDto, PresignDto } from './dto';
import { UploadsService } from './uploads.service';

@ApiTags('Uploads')
@Controller({ path: 'uploads', version: '1' })
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('presign')
  presign(@CurrentUser() user: CurrentUserPayload, @Body() dto: PresignDto) {
    return this.uploadsService.presignPut(user.id, dto);
  }

  @Post('confirm')
  confirm(@Body() dto: ConfirmUploadDto) {
    return this.uploadsService.confirmUpload(dto.key);
  }
}
