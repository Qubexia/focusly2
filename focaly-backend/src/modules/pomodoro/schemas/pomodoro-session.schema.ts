import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type PomodoroSessionDocument = HydratedDocument<PomodoroSession>;

export type PomodoroStatus = 'active' | 'paused' | 'completed' | 'aborted';

export type PomodoroBreakMode = 'cycles' | 'middle';

@Schema({ timestamps: true, collection: 'pomodoro_sessions' })
export class PomodoroSession {
  @Prop({ type: SchemaTypes.ObjectId, required: true, index: true })
  userId!: string;

  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  subjectId!: string | null;

  @Prop({ type: Date, required: true, index: true })
  startedAt!: Date;

  @Prop({ type: Date, default: null })
  endedAt!: Date | null;

  @Prop({ type: Number, default: 25, min: 1, max: 240 })
  focusMinutes!: number;

  @Prop({ type: Number, default: 5, min: 0, max: 60 })
  breakMinutes!: number;

  // Total planned session length. The session repeats focus/break cycles until
  // this many minutes have elapsed.
  @Prop({ type: Number, default: 120, min: 1, max: 480 })
  sessionMinutes!: number;

  // How breaks are laid out: 'cycles' repeats focus/break until the session
  // ends; 'middle' places a single break in the middle of the study time.
  @Prop({ type: String, enum: ['cycles', 'middle'], default: 'cycles' })
  breakMode!: PomodoroBreakMode;

  @Prop({ type: Number, default: 0 })
  completedCycles!: number;

  @Prop({ type: Number, default: 0 })
  totalFocusMinutes!: number;

  @Prop({
    type: String,
    enum: ['active', 'paused', 'completed', 'aborted'],
    required: true,
  })
  status!: PomodoroStatus;

  @Prop({ type: Date, required: true })
  lastTickAt!: Date;

  createdAt!: Date;
  updatedAt!: Date;
}

export const PomodoroSessionSchema = SchemaFactory.createForClass(PomodoroSession);

PomodoroSessionSchema.index({ userId: 1, startedAt: -1 });
PomodoroSessionSchema.index({ status: 1, lastTickAt: 1 });
