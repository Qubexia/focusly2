import { createHash } from 'node:crypto';
import type { Server } from 'node:http';

import { ClassSerializerInterceptor, INestApplication, VersioningType } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import helmet from 'helmet';
import request from 'supertest';

import { TransformInterceptor } from '../../../src/common/interceptors/transform.interceptor';
import { LegalModule } from '../../../src/modules/legal/legal.module';

/**
 * The privacy page is linked from app store listings, so the contract under test
 * is the public one: the URL never gains a version prefix, the response survives
 * the global response interceptors as raw HTML, and the CSP we send actually
 * permits the page's own inline blocks instead of silently breaking the toggle.
 */
describe('GET /privacy', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [LegalModule] }).compile();

    // Mirrors src/main.ts so the test exercises the same pipeline as production.
    app = moduleRef.createNestApplication();
    app.use(helmet());
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get(Reflector)),
      new TransformInterceptor(),
    );

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const server = (): Server => app.getHttpServer() as Server;

  it('serves the page as HTML at the unversioned path', async () => {
    const res = await request(server()).get('/privacy').expect(200);

    expect(res.headers['content-type']).toMatch(/^text\/html; charset=utf-8/);
    expect(res.text.startsWith('<!doctype html>')).toBe(true);
    expect(res.headers['cache-control']).toBe('public, max-age=300, must-revalidate');
  });

  it('is not exposed under the API version prefix', async () => {
    await request(server()).get('/v1/privacy').expect(404);
  });

  it('sends a CSP that whitelists every inline block by hash', async () => {
    const res = await request(server()).get('/privacy').expect(200);
    const csp = res.headers['content-security-policy'];

    expect(csp).toContain("default-src 'none'");
    expect(csp).not.toContain('unsafe-inline');

    // Recompute the hashes from the delivered body: if the HTML is edited and the
    // service stops hashing it correctly, the browser blocks it and this fails.
    const blocks = [...res.text.matchAll(/<(script|style)(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/\1>/gi)];
    expect(blocks.length).toBeGreaterThan(0);

    for (const [, , body] of blocks) {
      const hash = createHash('sha256').update(body!, 'utf8').digest('base64');
      expect(csp).toContain(`'sha256-${hash}'`);
    }
  });

  it('carries both language versions of the policy', async () => {
    const res = await request(server()).get('/privacy').expect(200);

    expect(res.text).toContain('id="en"');
    expect(res.text).toContain('id="ar"');
    expect(res.text).toContain('Privacy Policy');
    expect(res.text).toContain('سياسة الخصوصية');
  });

  it('requires no authentication and hits no database', async () => {
    // LegalModule imports nothing — if it ever grows a Mongo or Redis dependency
    // this module would fail to compile in isolation and this test would not boot.
    await request(server()).get('/privacy').expect(200);
  });
});
