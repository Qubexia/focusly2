import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { PlatformSetting, PlatformSettingDocument } from './schemas/platform-setting.schema';

const SINGLETON_KEY = 'global';

export interface ResolvedPlatformSettings {
  premiumGatingEnabled: boolean;
  freeSubjectLimit: number;
  aiHourlyLimit: number;
  aiMonthlyLimit: number;
  maintenanceMode: boolean;
  maintenanceMessage: string | null;
}

export interface UpdatePlatformSettingsInput {
  premiumGatingEnabled?: boolean;
  freeSubjectLimit?: number;
  aiHourlyLimit?: number;
  aiMonthlyLimit?: number;
  maintenanceMode?: boolean;
  maintenanceMessage?: string | null;
}

@Injectable()
export class PlatformSettingsService {
  constructor(
    @InjectModel(PlatformSetting.name)
    private readonly model: Model<PlatformSettingDocument>,
  ) {}

  private async getOrCreate(): Promise<PlatformSetting> {
    const doc = await this.model
      .findOneAndUpdate(
        { key: SINGLETON_KEY },
        { $setOnInsert: { key: SINGLETON_KEY } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      )
      .lean<PlatformSetting>()
      .exec();
    if (!doc) {
      throw new Error('Failed to initialise platform settings.');
    }
    return doc;
  }

  async resolve(): Promise<ResolvedPlatformSettings> {
    const doc = await this.getOrCreate();
    return {
      premiumGatingEnabled: doc.premiumGatingEnabled,
      freeSubjectLimit: doc.freeSubjectLimit,
      aiHourlyLimit: doc.aiHourlyLimit,
      aiMonthlyLimit: doc.aiMonthlyLimit,
      maintenanceMode: doc.maintenanceMode,
      maintenanceMessage: doc.maintenanceMessage,
    };
  }

  /** Public config exposed to mobile/web clients (no secrets). */
  async publicConfig(): Promise<ResolvedPlatformSettings & { updatedAt: Date | null }> {
    const doc = await this.getOrCreate();
    return {
      premiumGatingEnabled: doc.premiumGatingEnabled,
      freeSubjectLimit: doc.freeSubjectLimit,
      aiHourlyLimit: doc.aiHourlyLimit,
      aiMonthlyLimit: doc.aiMonthlyLimit,
      maintenanceMode: doc.maintenanceMode,
      maintenanceMessage: doc.maintenanceMessage,
      updatedAt: doc.updatedAt ?? null,
    };
  }

  async update(
    input: UpdatePlatformSettingsInput,
  ): Promise<ResolvedPlatformSettings & { updatedAt: Date | null }> {
    const set: Record<string, unknown> = {};
    if (input.premiumGatingEnabled !== undefined)
      set.premiumGatingEnabled = input.premiumGatingEnabled;
    if (input.freeSubjectLimit !== undefined) set.freeSubjectLimit = input.freeSubjectLimit;
    if (input.aiHourlyLimit !== undefined) set.aiHourlyLimit = input.aiHourlyLimit;
    if (input.aiMonthlyLimit !== undefined) set.aiMonthlyLimit = input.aiMonthlyLimit;
    if (input.maintenanceMode !== undefined) set.maintenanceMode = input.maintenanceMode;
    if (input.maintenanceMessage !== undefined) {
      set.maintenanceMessage =
        input.maintenanceMessage && input.maintenanceMessage.trim()
          ? input.maintenanceMessage.trim()
          : null;
    }

    await this.model
      .findOneAndUpdate(
        { key: SINGLETON_KEY },
        { $set: set, $setOnInsert: { key: SINGLETON_KEY } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      )
      .exec();

    return this.publicConfig();
  }
}
