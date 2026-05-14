import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type StreakDocument = HydratedDocument<Streak>;

export interface StreakReward {
  code: string;
  awardedAt: Date;
}

@Schema({ timestamps: true, collection: 'streaks' })
export class Streak {
  @Prop({ type: SchemaTypes.ObjectId, required: true, unique: true })
  userId!: string;

  @Prop({ type: Number, default: 0 })
  current!: number;

  @Prop({ type: Number, default: 0 })
  longest!: number;

  @Prop({ type: String, default: null })
  lastActiveDate!: string | null;

  @Prop({ type: Number, default: 0 })
  points!: number;

  @Prop({ type: [{ code: String, awardedAt: Date }], default: [] })
  rewards!: StreakReward[];

  createdAt!: Date;
  updatedAt!: Date;
}

export const StreakSchema = SchemaFactory.createForClass(Streak);
