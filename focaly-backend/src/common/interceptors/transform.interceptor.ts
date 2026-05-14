import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

function stripMongoFields(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) return value.map(stripMongoFields);
  if (typeof value !== 'object') return value;

  const src = value as Record<string, unknown>;
  if ('_doc' in src || typeof (src as { toObject?: unknown }).toObject === 'function') {
    const obj = (src as { toObject?: () => Record<string, unknown> }).toObject?.() ?? { ...src };
    return stripMongoFields(obj);
  }

  const out: Record<string, unknown> = {};
  for (const [key, val] of Object.entries(src)) {
    if (key === '__v') continue;
    if (key === '_id') {
      out.id = typeof val === 'object' && val !== null ? String(val) : val;
      continue;
    }
    out[key] = stripMongoFields(val);
  }
  return out;
}

@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(_ctx: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(map((data) => stripMongoFields(data)));
  }
}
