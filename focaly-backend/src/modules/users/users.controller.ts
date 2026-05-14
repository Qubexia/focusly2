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
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @CurrentUser() user: CurrentUserPayload,
    @UploadedFile() file?: { originalname: string },
  ): Promise<{ avatarUrl: string }> {
    if (!file) {
      throw new BadRequestException({
        code: ERROR_CODES.VALIDATION,
        message: 'Avatar file is required.',
      });
    }

    return this.usersService.uploadAvatar(user, file.originalname);
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
