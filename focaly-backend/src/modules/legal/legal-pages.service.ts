import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { Injectable } from '@nestjs/common';

export interface LegalPage {
  /** The full HTML document, read from disk once at startup. */
  html: string;
  /** Page-specific CSP that whitelists this document's own inline blocks by hash. */
  csp: string;
}

/**
 * Inline blocks only. A `src=`/`href=` variant would need a different CSP source,
 * and these pages are deliberately self-contained — no CDNs, no external assets.
 */
const INLINE_BLOCK = /<(script|style)(?![^>]*\b(?:src|href)=)[^>]*>([\s\S]*?)<\/\1>/gi;

function sha256(source: string): string {
  return `'sha256-${createHash('sha256').update(source, 'utf8').digest('base64')}'`;
}

/**
 * Serves the static legal pages (privacy policy, and any sibling documents added
 * later) that must be reachable without an account — app stores and Google
 * OAuth verification both require a public, un-authenticated URL.
 */
@Injectable()
export class LegalPagesService {
  private readonly cache = new Map<string, LegalPage>();

  getPrivacyPolicy(): LegalPage {
    return this.load('privacy-policy.html');
  }

  private load(file: string): LegalPage {
    const cached = this.cache.get(file);
    if (cached) return cached;

    const html = readFileSync(join(__dirname, 'pages', file), 'utf8');

    // helmet's default CSP forbids inline scripts, which would silently kill the
    // language toggle. Rather than loosening it with 'unsafe-inline', hash the
    // page's own blocks so the policy keeps working when the file is edited.
    const scripts: string[] = [];
    const styles: string[] = [];
    for (const [, tag, body] of html.matchAll(INLINE_BLOCK)) {
      (tag!.toLowerCase() === 'script' ? scripts : styles).push(sha256(body!));
    }

    const page: LegalPage = {
      html,
      csp: [
        "default-src 'none'",
        `script-src ${scripts.join(' ') || "'none'"}`,
        `style-src ${styles.join(' ') || "'none'"}`,
        "img-src 'self' data:",
        "base-uri 'none'",
        "form-action 'none'",
        "frame-ancestors 'none'",
      ].join('; '),
    };

    this.cache.set(file, page);
    return page;
  }
}
