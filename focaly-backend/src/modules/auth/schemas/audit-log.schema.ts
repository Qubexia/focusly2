import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, SchemaTypes } from 'mongoose';

export type AuditLogDocument = HydratedDocument<AuditLog>;

@Schema({
  collection: 'audit_logs',
  timestamps: { createdAt: true, updatedAt: false },
})
export class AuditLog {
  @Prop({ type: SchemaTypes.ObjectId, default: null, index: true })
  userId!: string | null;

  @Prop({ type: String, enum: ['user', 'admin', 'system', 'webhook'], required: true })
  actor!: 'user' | 'admin' | 'system' | 'webhook';

  @Prop({ required: true, index: true })
  eventType!: string;

  @Prop({ type: String, default: null })
  requestId!: string | null;

  @Prop({ type: String, default: null })
  ip!: string | null;

  @Prop({ type: String, default: null })
  userAgent!: string | null;

  @Prop({ type: SchemaTypes.Mixed, default: null })
  data!: Record<string, unknown> | null;

  createdAt!: Date;
}

export const AuditLogSchema = SchemaFactory.createForClass(AuditLog);

AuditLogSchema.index({ userId: 1, createdAt: -1 });
AuditLogSchema.index({ eventType: 1, createdAt: -1 });
AuditLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 31_536_000 });
