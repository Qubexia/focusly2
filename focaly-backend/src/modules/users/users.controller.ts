import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { FcmTokenDto } from '../auth/dto';

import { UpdateSettingsDto } from './dto/update-settings.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

const AVATAR_MAX_BYTES = 2_097_152;
const AVATAR_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

@ApiTags('Users')
@Controller({ path: 'users', version: '1' })
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  me(@CurrentUser() user: CurrentUserPayload): Promise<unknown> {
    return this.usersService.getCurrentUser(user);
  }

  @Patch('me')
  update(@CurrentUser() user: CurrentUserPayload, @Body() dto: UpdateUserDto): Promise<unknown> {
    return this.usersService.updateUser(user, dto);
  }

  @Patch('me/settings')
  updateSettings(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: UpdateSettingsDto,
  ): Promise<unknown> {
    return this.usersService.updateSettings(user, dto);
  }

  @Post('me/avatar')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: AVATAR_MAX_BYTES },
    }),
  )
  async uploadAvatar(
    @CurrentUser() user: CurrentUserPayload,
    @UploadedFile()
    file?: {
      originalname: string;
      mimetype?: string;
      buffer: Buffer;
      size: number;
    },
  ): Promise<{ avatarUrl: string }> {
    if (!file?.buffer?.length) {
      throw new BadRequestException({
        code: ERROR_CODES.VALIDATION,
        message: 'Avatar file is required.',
      });
    }

    if (file.mimetype && !AVATAR_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException({
        code: ERROR_CODES.VALIDATION,
        message: 'Unsupported avatar image type.',
      });
    }

    return this.usersService.uploadAvatar(user, file);
  }

  @Post('me/fcm-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  async registerFcmToken(
    @CurrentUser() user: CurrentUserPayload,
    @Body() dto: FcmTokenDto,
  ): Promise<void> {
    await this.usersService.registerFcmToken(user, dto);
  }

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAccount(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.usersService.deleteAccount(user);
  }
}
