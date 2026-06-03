import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import { api, authApi, tokenStore } from '@/lib/api';
import type { AdminUser } from '@/types/api';

interface AuthState {
  user: AdminUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

class AuthError extends Error {}

export function AuthProvider({ children }: { children: ReactNode }): JSX.Element {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    tokenStore.clear();
    setUser(null);
  }, []);

  const loadMe = useCallback(async () => {
    if (!tokenStore.access) {
      setUser(null);
      return;
    }
    try {
      const { data } = await api.get<AdminUser>('/users/me');
      setUser(data.role === 'admin' ? data : null);
      if (data.role !== 'admin') tokenStore.clear();
    } catch {
      setUser(null);
    }
  }, []);

  useEffect(() => {
    void loadMe().finally(() => setLoading(false));
    const onLogout = (): void => logout();
    window.addEventListener('focaly:logout', onLogout);
    return () => window.removeEventListener('focaly:logout', onLogout);
  }, [loadMe, logout]);

  const login = useCallback(async (email: string, password: string) => {
    const { data } = await authApi.post<{
      user: AdminUser;
      tokens: { accessToken: string; refreshToken: string };
    }>('/auth/login', { email, password, deviceId: tokenStore.deviceId });

    tokenStore.set(data.tokens.accessToken, data.tokens.refreshToken);

    // Re-fetch the canonical profile to confirm the admin role.
    const me = await api.get<AdminUser>('/users/me');
    if (me.data.role !== 'admin') {
      tokenStore.clear();
      throw new AuthError('This account does not have administrator access.');
    }
    setUser(me.data);
  }, []);

  const value = useMemo<AuthState>(
    () => ({ user, loading, login, logout }),
    [user, loading, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
