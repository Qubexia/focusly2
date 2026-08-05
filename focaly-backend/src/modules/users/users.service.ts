import { randomUUID } from 'crypto';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';

import { Inject, Injectable, NotFoundException, forwardRef } from '@nestjs/common';

import { CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { ERROR_CODES } from '../../common/dto/api-response';
import { AuthSessionsRepository } from '../auth/auth-sessions.repository';
import { FcmTokenDto } from '../auth/dto';
import { SubscriptionsService } from '../subscription/subscriptions.service';

import { UpdateSettingsDto } from './dto/update-settings.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersRepository } from './users.repository';

const AVATAR_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif']);

export interface AvatarUploadFile {
  originalname: string;
  mimetype?: string;
  buffer: Buffer;
  size: number;
}

/** Picks a safe extension from a client filename, defaulting to .jpg. */
function extensionForAvatar(fileName: string): string {
  const match = /\.[a-z0-9]{1,5}$/i.exec(fileName ?? '');
  const ext = match?.[0]?.toLowerCase() ?? '';
  return AVATAR_EXTENSIONS.has(ext) ? ext : '.jpg';
}

@Injectable()
export class UsersService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly authSessionsRepository: AuthSessionsRepository,
    @Inject(forwardRef(() => SubscriptionsService))
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  async getCurrentUser(user: CurrentUserPayload): Promise<unknown> {
    await this.subscriptionsService.syncUserPlanFromSubscription(user.id);
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

  async uploadAvatar(
    user: CurrentUserPayload,
    file: AvatarUploadFile,
  ): Promise<{ avatarUrl: string }> {
    // Store on the API server disk and expose via /uploads/... static files.
    // The client filename is never trusted in the key.
    const ext = extensionForAvatar(file.originalname);
    const objectName = `${randomUUID()}${ext}`;
    const relativeDir = join('avatars', user.id);
    const storageRoot = join(process.cwd(), 'storage');
    const absoluteDir = join(storageRoot, relativeDir);
    await mkdir(absoluteDir, { recursive: true });
    await writeFile(join(absoluteDir, objectName), file.buffer);

    // Relative path so clients resolve against their configured API base URL
    // (localhost vs LAN IP vs production host).
    const avatarUrl = `/uploads/avatars/${user.id}/${objectName}`;

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
