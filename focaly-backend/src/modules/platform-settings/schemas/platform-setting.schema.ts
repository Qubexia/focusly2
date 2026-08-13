import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type PlatformSettingDocument = HydratedDocument<PlatformSetting>;

/** Singleton document holding admin-configurable platform settings. */
@Schema({ timestamps: true, collection: 'platform_settings' })
export class PlatformSetting {
  @Prop({ type: String, required: true, unique: true, default: 'global' })
  key!: string;

  /** When false, all authenticated users get premium features (dev/demo mode). */
  @Prop({ type: Boolean, default: true })
  premiumGatingEnabled!: boolean;

  /** Max active subjects for free-plan users. Premium users are unlimited. */
  @Prop({ type: Number, default: 3, min: 0, max: 100 })
  freeSubjectLimit!: number;

  @Prop({ type: Number, default: 5, min: 1, max: 1000 })
  aiHourlyLimit!: number;

  @Prop({ type: Number, default: 30, min: 1, max: 10000 })
  aiMonthlyLimit!: number;

  /**
   * Premium prices in the smallest currency unit (e.g. piastres for EGP).
   * Null falls back to the PAYMOB_PREMIUM_*_AMOUNT_CENTS env vars, so an
   * untouched deployment keeps behaving exactly as before.
   */
  @Prop({ type: Number, default: null, min: 0 })
  premiumMonthlyPriceCents!: number | null;

  @Prop({ type: Number, default: null, min: 0 })
  premiumYearlyPriceCents!: number | null;

  /** ISO-4217 code the prices are charged in. Null falls back to PAYMOB_CURRENCY. */
  @Prop({ type: String, default: null, uppercase: true, trim: true })
  currency!: string | null;

  /** When true, non-admin API requests return maintenance response. */
  @Prop({ type: Boolean, default: false })
  maintenanceMode!: boolean;

  @Prop({ type: String, default: null })
  maintenanceMessage!: string | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const PlatformSettingSchema = SchemaFactory.createForClass(PlatformSetting);
