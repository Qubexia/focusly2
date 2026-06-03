import { UnauthorizedException } from '@nestjs/common';

import { AuthService } from '../../../src/modules/auth/auth.service';
import { RefreshTokenClaims, TokenPairResult } from '../../../src/modules/auth/jwt.service';

describe('AuthService refresh rotation', () => {
  it('rotates once, then revokes family on reused token', async () => {
    const session = {
      id: 'session-1',
      userId: 'user-1',
      family: 'family-1',
      refreshTokenHash: 'hash:old-refresh',
    };
    const redisStore = new Map<string, string>();
    const revokeFamily = jest.fn(() => Promise.resolve(undefined));
    const auditCreate = jest.fn(() => Promise.resolve(undefined));

    const authService = new AuthService(
      {
        findActiveById: jest.fn(() =>
          Promise.resolve({
            id: 'user-1',
            email: 'student@example.com',
            role: 'user',
            plan: 'free',
            premiumUntil: null,
            emailVerified: true,
          }),
        ),
        updateOne: jest.fn(() => Promise.resolve(undefined)),
      } as never,
      {
        findActiveById: jest.fn(() => Promise.resolve(session)),
        updateRefreshToken: jest.fn((_sessionId: string, refreshTokenHash: string) => {
          session.refreshTokenHash = refreshTokenHash;
          return Promise.resolve(undefined);
        }),
        revokeFamily,
      } as never,
      {
        signTokenPair: jest.fn(
          (): TokenPairResult => ({
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
            accessExpiresIn: 900,
            refreshExpiresIn: 2_592_000,
            refreshJti: 'jti-2',
          }),
        ),
        getRefreshTtlSeconds: jest.fn(() => 2_592_000),
      } as never,
      {
        hash: jest.fn((value: string) => Promise.resolve(`hash:${value}`)),
        verify: jest.fn((hash: string, value: string) => Promise.resolve(hash === `hash:${value}`)),
      },
      {} as never,
      {} as never,
      {
        get: jest.fn((key: string) => Promise.resolve(redisStore.get(key) ?? null)),
        set: jest.fn((key: string, value: string) => {
          redisStore.set(key, value);
          return Promise.resolve('OK');
        }),
      } as never,
      { create: auditCreate } as never,
      { get: jest.fn(() => 'focusly://verify-email') } as never,
    );

    const claims: RefreshTokenClaims = {
      sub: 'user-1',
      sessionId: 'session-1',
      deviceId: 'device-1',
      family: 'family-1',
      jti: 'jti-1',
      type: 'refresh',
    };

    await expect(
      authService.refresh({ refreshToken: 'old-refresh', deviceId: 'device-1' }, claims, {
        ip: '127.0.0.1',
        userAgent: 'jest',
        requestId: 'req-1',
      }),
    ).resolves.toMatchObject({ refreshToken: 'new-refresh' });

    await expect(
      authService.refresh({ refreshToken: 'old-refresh', deviceId: 'device-1' }, claims, {
        ip: '127.0.0.1',
        userAgent: 'jest',
        requestId: 'req-2',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(revokeFamily).toHaveBeenCalledWith('user-1', 'family-1');
    expect(auditCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user-1',
        eventType: 'auth.refresh.reuse',
      }),
    );
  });
});
