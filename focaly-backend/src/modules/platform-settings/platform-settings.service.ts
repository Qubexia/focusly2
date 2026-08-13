import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
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

/** Effective premium pricing: database value when set, env var otherwise. */
export interface ResolvedPricing {
  monthlyCents: number;
  yearlyCents: number;
  currency: string;
  /** Where each price came from — surfaced in the admin UI so it is never a guess. */
  source: { monthly: 'database' | 'env'; yearly: 'database' | 'env'; currency: 'database' | 'env' };
}

export interface UpdatePlatformSettingsInput {
  premiumGatingEnabled?: boolean;
  freeSubjectLimit?: number;
  aiHourlyLimit?: number;
  aiMonthlyLimit?: number;
  maintenanceMode?: boolean;
  maintenanceMessage?: string | null;
  premiumMonthlyPriceCents?: number | null;
  premiumYearlyPriceCents?: number | null;
  currency?: string | null;
}

@Injectable()
export class PlatformSettingsService {
  constructor(
    @InjectModel(PlatformSetting.name)
    private readonly model: Model<PlatformSettingDocument>,
    private readonly config: ConfigService,
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

  /**
   * Effective premium pricing. Every payment path reads prices through here so
   * an admin price change takes effect without a redeploy, while a deployment
   * that never touches the dashboard keeps using its env vars.
   */
  async resolvePricing(): Promise<ResolvedPricing> {
    const doc = await this.getOrCreate();

    const envMonthly = this.config.get<number>('paymob.monthlyAmountCents') ?? 0;
    const envYearly = this.config.get<number>('paymob.yearlyAmountCents') ?? 0;
    const envCurrency = (this.config.get<string>('paymob.currency') ?? 'EGP').toUpperCase();

    const monthlySet = typeof doc.premiumMonthlyPriceCents === 'number';
    const yearlySet = typeof doc.premiumYearlyPriceCents === 'number';
    const currencySet = Boolean(doc.currency);

    return {
      monthlyCents: monthlySet ? doc.premiumMonthlyPriceCents! : envMonthly,
      yearlyCents: yearlySet ? doc.premiumYearlyPriceCents! : envYearly,
      currency: currencySet ? doc.currency!.toUpperCase() : envCurrency,
      source: {
        monthly: monthlySet ? 'database' : 'env',
        yearly: yearlySet ? 'database' : 'env',
        currency: currencySet ? 'database' : 'env',
      },
    };
  }

  /** Public config exposed to mobile/web clients (no secrets). */
  async publicConfig(): Promise<
    ResolvedPlatformSettings & { pricing: ResolvedPricing; updatedAt: Date | null }
  > {
    const [doc, pricing] = await Promise.all([this.getOrCreate(), this.resolvePricing()]);
    return {
      premiumGatingEnabled: doc.premiumGatingEnabled,
      freeSubjectLimit: doc.freeSubjectLimit,
      aiHourlyLimit: doc.aiHourlyLimit,
      aiMonthlyLimit: doc.aiMonthlyLimit,
      maintenanceMode: doc.maintenanceMode,
      maintenanceMessage: doc.maintenanceMessage,
      pricing,
      updatedAt: doc.updatedAt ?? null,
    };
  }

  async update(
    input: UpdatePlatformSettingsInput,
  ): Promise<ResolvedPlatformSettings & { pricing: ResolvedPricing; updatedAt: Date | null }> {
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
    // null clears the override and hands the price back to the env var.
    if (input.premiumMonthlyPriceCents !== undefined) {
      set.premiumMonthlyPriceCents = input.premiumMonthlyPriceCents;
    }
    if (input.premiumYearlyPriceCents !== undefined) {
      set.premiumYearlyPriceCents = input.premiumYearlyPriceCents;
    }
    if (input.currency !== undefined) {
      set.currency = input.currency ? input.currency.trim().toUpperCase() : null;
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
