import { Controller, Get, Res, VERSION_NEUTRAL } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import type { Response } from 'express';

import { Public } from '../../common/decorators/public.decorator';

import { LegalPagesService } from './legal-pages.service';

/**
 * Version-neutral so the public URL stays `/privacy` rather than `/v1/privacy` —
 * this link goes into app store listings and cannot change when the API version does.
 */
@Controller({ version: VERSION_NEUTRAL })
export class LegalController {
  constructor(private readonly pages: LegalPagesService) {}

  @Get('privacy')
  @Public()
  @SkipThrottle()
  @ApiExcludeEndpoint()
  privacyPolicy(@Res({ passthrough: true }) res: Response): string {
    const page = this.pages.getPrivacyPolicy();

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Security-Policy', page.csp);
    res.setHeader('Cache-Control', 'public, max-age=300, must-revalidate');

    return page.html;
  }
}
