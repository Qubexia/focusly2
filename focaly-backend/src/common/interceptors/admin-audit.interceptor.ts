import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Request } from 'express';
import { Model, Types } from 'mongoose';
import { Observable, tap } from 'rxjs';

import { AuditLog, AuditLogDocument } from '../../modules/auth/schemas/audit-log.schema';

/** Never persisted — an audit trail must not become a secret store. */
const REDACTED_KEYS = new Set([
  'password',
  'newpassword',
  'currentpassword',
  'apikey',
  'token',
  'accesstoken',
  'refreshtoken',
  'secret',
  'hmac',
  'otp',
]);

const METHOD_VERBS: Record<string, string> = {
  POST: 'create',
  PATCH: 'update',
  PUT: 'update',
  DELETE: 'delete',
};

/**
 * Records every state-changing admin request in `audit_logs`. Bans, deletions,
 * plan grants and settings changes were previously untraceable: the request
 * logger only wrote a log line, and never for `/v1/admin/*` at all.
 *
 * Reads (GET/HEAD/OPTIONS) are skipped — they carry no accountability weight
 * and would bury the actions that do.
 */
@Injectable()
export class AdminAuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger(AdminAuditInterceptor.name);

  constructor(
    @InjectModel(AuditLog.name) private readonly auditLogModel: Model<AuditLogDocument>,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<AuditedRequest>();

    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next.handle();
    }

    return next.handle().pipe(
      tap({
        next: () => void this.record(req, 'success'),
        error: (error: unknown) => void this.record(req, 'error', error),
      }),
    );
  }

  private async record(req: AuditedRequest, result: 'success' | 'error', error?: unknown) {
    try {
      await this.auditLogModel.create({
        userId: toObjectId(subjectUserId(req)),
        actor: 'admin',
        actorUserId: toObjectId(req.user?.id),
        eventType: eventTypeFor(req),
        requestId: requestIdOf(req),
        ip: req.ip ?? null,
        userAgent: req.headers['user-agent'] ?? null,
        data: {
          method: req.method,
          path: req.originalUrl ?? req.url,
          params: req.params ?? {},
          body: redact(req.body),
          result,
          ...(error ? { error: errorMessage(error) } : {}),
        },
      });
    } catch (writeError) {
      // A failed audit write must never turn a successful admin action into a 500.
      this.logger.error(`Failed to write admin audit entry: ${errorMessage(writeError)}`);
    }
  }
}

interface AuditedRequest extends Request {
  user?: { id?: string };
}

/** `admin.users.ban`, `admin.users.update`, `admin.payments.refund`… */
function eventTypeFor(req: AuditedRequest): string {
  const routePath: unknown = req.route?.path;
  const path = typeof routePath === 'string' ? routePath : req.path;
  const segments = path
    .split('/')
    .filter(Boolean)
    .filter((s: string) => s !== 'v1');
  const named = segments.filter((s: string) => !s.startsWith(':'));
  const endsWithParam = segments[segments.length - 1]?.startsWith(':') ?? false;

  const parts = endsWithParam
    ? [...named, METHOD_VERBS[req.method] ?? req.method.toLowerCase()]
    : named;

  return parts.join('.') || 'admin.unknown';
}

/** The account an action targets, when the route names one. */
function subjectUserId(req: AuditedRequest): string | undefined {
  const params = (req.params ?? {}) as Record<string, string>;
  const candidate = params.userId ?? params.id;
  return candidate && Types.ObjectId.isValid(candidate) ? candidate : undefined;
}

/** `id` is stamped on the request by the request-id middleware / pino. */
function requestIdOf(req: AuditedRequest): string | null {
  const id: unknown = (req as { id?: unknown }).id;
  return typeof id === 'string' ? id : null;
}

function toObjectId(value?: string): Types.ObjectId | null {
  return value && Types.ObjectId.isValid(value) ? new Types.ObjectId(value) : null;
}

function redact(body: unknown): unknown {
  if (Array.isArray(body)) return body.map(redact);
  if (!body || typeof body !== 'object') return body ?? null;

  return Object.entries(body as Record<string, unknown>).reduce<Record<string, unknown>>(
    (acc, [key, value]) => {
      acc[key] = REDACTED_KEYS.has(key.toLowerCase())
        ? '[redacted]'
        : typeof value === 'object'
          ? redact(value)
          : value;
      return acc;
    },
    {},
  );
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
