import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Avatars are written to ./storage and served by Nest at /uploads/*, but in
 * production every request first hits nginx. nginx only forwards the paths it
 * has a location block for — anything else falls through to the admin SPA
 * catch-all, which answers `200 text/html` for a missing file instead of the
 * image. A stored avatar then loads as HTML and the client shows nothing.
 *
 * So the contract under test is the seam between the two: whatever prefix
 * main.ts mounts static uploads on must also be routed to the API upstream by
 * the nginx config we ship.
 */
describe('production routing for static uploads', () => {
  const repoRoot = join(__dirname, '..', '..', '..', '..');
  const mainTs = readFileSync(join(repoRoot, 'focaly-backend', 'src', 'main.ts'), 'utf8');
  const nginxConf = readFileSync(join(repoRoot, 'deploy', 'nginx', 'zakerlyai.tech.conf'), 'utf8');

  /** The prefix Nest serves ./storage under, read from main.ts itself. */
  const staticPrefix = /useStaticAssets\([\s\S]*?prefix:\s*'([^']+)'/.exec(mainTs)?.[1];

  /** `location <path> { <body> }` blocks, flattened to [path, body] pairs. */
  const locations = [...nginxConf.matchAll(/location\s+(=\s+)?([^\s{]+)\s*\{([^}]*)\}/g)].map(
    ([, exact, path, body]) => ({ exact: Boolean(exact), path: path!, body: body! }),
  );

  const apiUpstream = /upstream\s+(\S+)\s*\{/.exec(nginxConf)?.[1];

  it('mounts uploads on a known prefix', () => {
    expect(staticPrefix).toBe('/uploads/');
    expect(apiUpstream).toBeTruthy();
  });

  it('forwards that prefix to the API instead of the SPA catch-all', () => {
    const uploads = locations.find((l) => !l.exact && l.path === staticPrefix);

    expect(uploads).toBeDefined();
    expect(uploads!.body).toContain(`proxy_pass http://${apiUpstream};`);
  });

  it('keeps the SPA catch-all from answering upload requests', () => {
    // nginx picks the longest matching prefix, so a dedicated /uploads/ block
    // wins over `location /`. Guard the assumption that / is still a catch-all
    // serving files from disk — if it ever gained a `proxy_pass`, the ordering
    // reasoning above would need revisiting.
    const spa = locations.find((l) => !l.exact && l.path === '/');

    expect(spa).toBeDefined();
    expect(spa!.body).not.toContain('proxy_pass');
    expect(spa!.body).toContain('try_files');
  });
});
