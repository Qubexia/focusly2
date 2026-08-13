import { CallHandler, ExecutionContext } from '@nestjs/common';
import { Model } from 'mongoose';
import { firstValueFrom, of, throwError } from 'rxjs';

import { AdminAuditInterceptor } from '../../../src/common/interceptors/admin-audit.interceptor';
import { AuditLogDocument } from '../../../src/modules/auth/schemas/audit-log.schema';

const ADMIN_ID = '507f1f77bcf86cd799439011';
const TARGET_ID = '507f1f77bcf86cd799439022';

interface RequestOverrides {
  method?: string;
  routePath?: string;
  params?: Record<string, string>;
  body?: unknown;
}

function contextFor(overrides: RequestOverrides = {}): ExecutionContext {
  const request = {
    method: overrides.method ?? 'POST',
    route: { path: overrides.routePath ?? '/v1/admin/users/:id/ban' },
    path: overrides.routePath ?? '/v1/admin/users/:id/ban',
    originalUrl: '/v1/admin/users/x/ban',
    params: overrides.params ?? { id: TARGET_ID },
    body: overrides.body ?? {},
    headers: { 'user-agent': 'jest' },
    ip: '10.0.0.1',
    user: { id: ADMIN_ID },
  };

  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

const handlerOf = (value: unknown): CallHandler => ({ handle: () => of(value) });

describe('AdminAuditInterceptor', () => {
  let create: jest.Mock;
  let interceptor: AdminAuditInterceptor;

  beforeEach(() => {
    create = jest.fn(() => Promise.resolve(undefined));
    interceptor = new AdminAuditInterceptor({ create } as unknown as Model<AuditLogDocument>);
  });

  /** Await the microtask the interceptor's tap() schedules for the write. */
  const flush = (): Promise<void> => new Promise((resolve) => setImmediate(resolve));

  it('records the admin, the target and the action for a ban', async () => {
    await firstValueFrom(interceptor.intercept(contextFor(), handlerOf({ ok: true })));
    await flush();

    expect(create).toHaveBeenCalledTimes(1);
    const entry = create.mock.calls[0][0] as Record<string, any>;
    expect(entry.actor).toBe('admin');
    expect(entry.eventType).toBe('admin.users.ban');
    expect(String(entry.actorUserId)).toBe(ADMIN_ID);
    expect(String(entry.userId)).toBe(TARGET_ID);
    expect(entry.data.result).toBe('success');
  });

  it('derives a verb for routes that end in a parameter', async () => {
    await firstValueFrom(
      interceptor.intercept(
        contextFor({ method: 'PATCH', routePath: '/v1/admin/users/:id' }),
        handlerOf({}),
      ),
    );
    await flush();

    expect((create.mock.calls[0][0] as Record<string, any>).eventType).toBe('admin.users.update');
  });

  it('never persists secrets from the request body', async () => {
    await firstValueFrom(
      interceptor.intercept(
        contextFor({
          method: 'PATCH',
          routePath: '/v1/admin/ai/settings',
          params: {},
          body: { model: 'gpt-4o-mini', apiKey: 'sk-live-should-never-be-stored' },
        }),
        handlerOf({}),
      ),
    );
    await flush();

    const entry = create.mock.calls[0][0] as Record<string, any>;
    expect(entry.data.body).toEqual({ model: 'gpt-4o-mini', apiKey: '[redacted]' });
    expect(JSON.stringify(entry)).not.toContain('sk-live');
  });

  it('skips reads — only state changes are worth auditing', async () => {
    await firstValueFrom(
      interceptor.intercept(contextFor({ method: 'GET', routePath: '/v1/admin/users' }), handlerOf([])),
    );
    await flush();

    expect(create).not.toHaveBeenCalled();
  });

  it('records failed attempts too', async () => {
    const failing: CallHandler = { handle: () => throwError(() => new Error('boom')) };

    await expect(firstValueFrom(interceptor.intercept(contextFor(), failing))).rejects.toThrow(
      'boom',
    );
    await flush();

    const entry = create.mock.calls[0][0] as Record<string, any>;
    expect(entry.data.result).toBe('error');
    expect(entry.data.error).toBe('boom');
  });

  it('lets the action succeed even when the audit write fails', async () => {
    create.mockRejectedValueOnce(new Error('mongo down'));

    await expect(
      firstValueFrom(interceptor.intercept(contextFor(), handlerOf({ ok: true }))),
    ).resolves.toEqual({ ok: true });
  });
});
