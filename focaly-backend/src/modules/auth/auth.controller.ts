import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request, Response } from 'express';

import { CurrentUser, CurrentUserPayload } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { JwtRefreshGuard } from '../../common/guards/jwt-refresh.guard';

import { AuthService, getRequestMeta } from './auth.service';
import {
  ForgotPasswordDto,
  GoogleLoginDto,
  LoginDto,
  RefreshDto,
  RegisterDto,
  ResetPasswordDto,
  VerifyEmailDto,
} from './dto';
import { RefreshTokenClaims } from './jwt.service';

@ApiTags('Auth')
@Controller({ path: 'auth', version: '1' })
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Public()
  async register(@Body() dto: RegisterDto, @Req() req: Request): Promise<unknown> {
    const deviceId = req.get('x-device-id') ?? undefined;
    return await this.authService.register(dto, getRequestMeta(req), deviceId);
  }

  @Post('login')
  @Public()
  async login(@Body() dto: LoginDto, @Req() req: Request): Promise<unknown> {
    return await this.authService.login(dto, getRequestMeta(req));
  }

  @Post('google')
  @Public()
  async google(@Body() dto: GoogleLoginDto, @Req() req: Request): Promise<unknown> {
    return await this.authService.googleLogin(dto, getRequestMeta(req));
  }

  @Post('refresh')
  @Public()
  @UseGuards(JwtRefreshGuard)
  @ApiBearerAuth('bearerRefresh')
  async refresh(
    @Body() dto: RefreshDto,
    @Req() req: Request & { refreshTokenPayload?: RefreshTokenClaims },
  ): Promise<unknown> {
    return await this.authService.refresh(dto, req.refreshTokenPayload!, getRequestMeta(req));
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.authService.logout(user);
  }

  @Post('logout-all')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutAll(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.authService.logoutAll(user);
  }

  @Post('forgot-password')
  @Public()
  @HttpCode(HttpStatus.NO_CONTENT)
  async forgotPassword(@Body() dto: ForgotPasswordDto): Promise<void> {
    await this.authService.forgotPassword(dto);
  }

  @Post('reset-password')
  @Public()
  @HttpCode(HttpStatus.NO_CONTENT)
  async resetPassword(@Body() dto: ResetPasswordDto): Promise<void> {
    await this.authService.resetPassword(dto);
  }

  @Post('verify-email')
  @Public()
  @HttpCode(HttpStatus.NO_CONTENT)
  async verifyEmail(@Body() dto: VerifyEmailDto): Promise<void> {
    await this.authService.verifyEmail(dto);
  }

  /**
   * Web verification page opened from the email link. Verifies server-side and
   * returns an HTML page so it works in any browser without the app installed.
   */
  @Get('verify-email')
  @Public()
  async verifyEmailWeb(@Query('token') token: string, @Res() res: Response): Promise<void> {
    const { status, html } = await this.authService.verifyEmailFromLink(token ?? '');
    res.status(status).type('html').send(html);
  }

  @Post('resend-verification')
  @HttpCode(HttpStatus.NO_CONTENT)
  async resendVerification(@CurrentUser() user: CurrentUserPayload): Promise<void> {
    await this.authService.resendVerificationEmail(user);
  }

  @Get('sessions')
  async sessions(@CurrentUser() user: CurrentUserPayload): Promise<unknown> {
    return await this.authService.listSessions(user);
  }

  @Delete('sessions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async revokeSession(
    @CurrentUser() user: CurrentUserPayload,
    @Param('id') sessionId: string,
  ): Promise<void> {
    await this.authService.revokeSession(user, sessionId);
  }
}
