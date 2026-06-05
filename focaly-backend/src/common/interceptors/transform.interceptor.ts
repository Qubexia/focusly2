import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

function mongoIdToString(value: unknown): string {
  const candidate = value as { toHexString?: () => string };
  if (typeof candidate.toHexString === 'function') {
    return candidate.toHexString();
  }
  return String(value);
}

function isMongoIdLike(value: unknown): boolean {
  if (!value || typeof value !== 'object') return false;

  const candidate = value as {
    _bsontype?: unknown;
    constructor?: { name?: unknown };
    toHexString?: unknown;
  };

  return (
    candidate._bsontype === 'ObjectId' ||
    candidate.constructor?.name === 'ObjectId' ||
    typeof candidate.toHexString === 'function'
  );
}

function stripMongoFields(value: unknown, ancestors: WeakSet<object> = new WeakSet()): unknown {
  if (value === null || value === undefined) return value;
  if (value instanceof Date) return value.toISOString();
  if (isMongoIdLike(value)) return mongoIdToString(value);
  if (typeof value !== 'object') return value;

  // Guard against circular references (e.g. an Express Response leaking in).
  // Track only the current recursion path so legitimately shared (non-circular)
  // references are still emitted.
  if (ancestors.has(value)) return undefined;
  ancestors.add(value);
  try {
    if (Array.isArray(value)) {
      return value.map((item) => stripMongoFields(item, ancestors));
    }

    const src = value as Record<string, unknown>;
    if ('_doc' in src || typeof (src as { toObject?: unknown }).toObject === 'function') {
      const obj = (src as { toObject?: () => Record<string, unknown> }).toObject?.() ?? { ...src };
      return stripMongoFields(obj, ancestors);
    }

    const out: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(src)) {
      if (key === '__v') continue;
      if (key === '_id') {
        out.id =
          typeof val === 'object' && val !== null && isMongoIdLike(val)
            ? mongoIdToString(val)
            : val;
        continue;
      }
      out[key] = stripMongoFields(val, ancestors);
    }
    return out;
  } finally {
    ancestors.delete(value);
  }
}

@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(_ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(map((data) => stripMongoFields(data)));
  }
}
