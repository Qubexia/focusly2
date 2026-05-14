import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema({ _id: false })
export class UserNotificationSettings {
  @Prop({ type: Boolean, default: true })
  reminders!: boolean;

  @Prop({ type: Boolean, default: true })
  streak!: boolean;

  @Prop({ type: Boolean, default: false })
  marketing!: boolean;
}

export const defaultNotificationSettings = (): UserNotificationSettings => ({
  reminders: true,
  streak: true,
  marketing: false,
});

@Schema({ _id: false })
export class UserSettings {
  @Prop({ type: String, default: 'en-US' })
  locale!: string;

  @Prop({ type: String, default: 'UTC' })
  timezone!: string;

  @Prop({ type: Boolean, default: false })
  focusMode!: boolean;

  @Prop({ type: UserNotificationSettings, default: defaultNotificationSettings })
  notifications!: UserNotificationSettings;
}

export const defaultUserSettings = (): UserSettings => ({
  locale: 'en-US',
  timezone: 'UTC',
  focusMode: false,
  notifications: defaultNotificationSettings(),
});

@Schema({ timestamps: true, collection: 'users' })
export class User {
  @Prop({ required: true, lowercase: true, trim: true, unique: true })
  email!: string;

  @Prop({ type: String, default: null })
  passwordHash!: string | null;

  @Prop({ type: String, sparse: true, unique: true })
  googleId?: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ type: String, default: null })
  avatarUrl!: string | null;

  @Prop({ type: Boolean, default: false })
  emailVerified!: boolean;

  @Prop({ type: String, enum: ['user', 'admin'], default: 'user' })
  role!: 'user' | 'admin';

  @Prop({ type: String, enum: ['free', 'premium'], default: 'free' })
  plan!: 'free' | 'premium';

  @Prop({ type: Date, default: null })
  premiumUntil!: Date | null;

  @Prop({ type: UserSettings, default: defaultUserSettings })
  settings!: UserSettings;

  @Prop({ type: Number, default: 0 })
  totalPoints!: number;

  @Prop({ type: Date, default: null })
  lastActiveAt!: Date | null;

  @Prop({ type: Boolean, default: false, index: true })
  isDeleted!: boolean;

  @Prop({ type: Date, default: null })
  deletedAt!: Date | null;

  createdAt!: Date;
  updatedAt!: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ deletedAt: 1 });
