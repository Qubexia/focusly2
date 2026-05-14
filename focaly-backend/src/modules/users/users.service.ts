import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { AuthSessionsRepository } from '../auth/auth-sessions.repository';
import { FcmTokenDto } from '../auth/dto';

import { UpdateSettingsDto } from './dto/update-settings.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersRepository } from './users.repository';

@Injectable()
export class UsersService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly authSessionsRepository: AuthSessionsRepository,
    private readonly configService: ConfigService,
  ) {}

  async getCurrentUser(user: CurrentUserPayload): Promise<unknown> {
    const entity = await this.usersRepository.findActiveById(user.id);
    if (!entity) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'User was not found.',
      });
    }

    return entity;
  }

  async updateUser(user: CurrentUserPayload, dto: UpdateUserDto): Promise<unknown> {
    const update: Record<string, unknown> = {};
    if (dto.name !== undefined) update.name = dto.name;
    if (dto.avatarUrl !== undefined) update.avatarUrl = dto.avatarUrl;
    if (dto.locale !== undefined) update['settings.locale'] = dto.locale;
    if (dto.timezone !== undefined) update['settings.timezone'] = dto.timezone;

    const updated = await this.usersRepository.updateById(user.id, { $set: update });
    if (!updated) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'User was not found.',
      });
    }

    return updated;
  }

  async updateSettings(user: CurrentUserPayload, dto: UpdateSettingsDto): Promise<unknown> {
    const update: Record<string, unknown> = {};
    if (dto.locale !== undefined) update['settings.locale'] = dto.locale;
    if (dto.timezone !== undefined) update['settings.timezone'] = dto.timezone;
    if (dto.focusMode !== undefined) update['settings.focusMode'] = dto.focusMode;
    if (dto.notifications?.reminders !== undefined) {
      update['settings.notifications.reminders'] = dto.notifications.reminders;
    }
    if (dto.notifications?.streak !== undefined) {
      update['settings.notifications.streak'] = dto.notifications.streak;
    }
    if (dto.notifications?.marketing !== undefined) {
      update['settings.notifications.marketing'] = dto.notifications.marketing;
    }

    const updated = await this.usersRepository.updateById(user.id, { $set: update });
    if (!updated) {
      throw new NotFoundException({
        code: ERROR_CODES.NOT_FOUND,
        message: 'User was not found.',
      });
    }

    return updated.settings;
  }

  async uploadAvatar(user: CurrentUserPayload, fileName: string): Promise<{ avatarUrl: string }> {
    const bucket = this.configService.getOrThrow<string>('s3.bucket');
    const region = this.configService.getOrThrow<string>('s3.region');
    const avatarUrl = `https://${bucket}.s3.${region}.amazonaws.com/avatars/${user.id}/${fileName}`;

    await this.usersRepository.updateOne({ _id: user.id }, { $set: { avatarUrl } });
    return { avatarUrl };
  }

  registerFcmToken(user: CurrentUserPayload, dto: FcmTokenDto): Promise<void> {
    return this.authSessionsRepository.setFcmToken(user.sessionId, dto.fcmToken);
  }

  async deleteAccount(user: CurrentUserPayload): Promise<void> {
    await this.usersRepository.markDeleted(user.id);
    await this.authSessionsRepository.revokeAllByUserId(user.id);
  }
}
