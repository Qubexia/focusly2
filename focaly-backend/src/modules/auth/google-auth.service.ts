import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

import { ERROR_CODES } from '../../common/dto/api-response';

export interface GoogleUserProfile {
  googleId: string;
  email: string;
  emailVerified: boolean;
  name: string;
  picture?: string;
}

@Injectable()
export class GoogleAuthService {
  private readonly clientId: string;
  private readonly client: OAuth2Client;

  constructor(configService: ConfigService) {
    this.clientId = configService.get<string>('jwt.googleClientId') ?? '';
    this.client = new OAuth2Client(this.clientId || undefined);
  }

  async verifyIdToken(idToken: string): Promise<GoogleUserProfile> {
    if (!this.clientId) {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Google sign-in is not configured.',
      });
    }

    const ticket = await this.client
      .verifyIdToken({ idToken, audience: this.clientId })
      .catch(() => null);
    const payload = ticket?.getPayload();
    if (!payload?.sub || !payload.email) {
      throw new UnauthorizedException({
        code: ERROR_CODES.UNAUTHORIZED,
        message: 'Google token is invalid.',
      });
    }

    return {
      googleId: payload.sub,
      email: payload.email.toLowerCase(),
      emailVerified: payload.email_verified ?? false,
      name: payload.name ?? payload.email,
      picture: payload.picture,
    };
  }
}
