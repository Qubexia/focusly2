import axios, {
  AxiosError,
  type AxiosInstance,
  type InternalAxiosRequestConfig,
} from 'axios';

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:5000/v1';

const ACCESS_KEY = 'focaly_admin_access';
const REFRESH_KEY = 'focaly_admin_refresh';
const DEVICE_KEY = 'focaly_admin_device';

export const tokenStore = {
  get access(): string | null {
    return localStorage.getItem(ACCESS_KEY);
  },
  get refresh(): string | null {
    return localStorage.getItem(REFRESH_KEY);
  },
  get deviceId(): string {
    let id = localStorage.getItem(DEVICE_KEY);
    if (!id) {
      id = `admin-web-${Math.random().toString(36).slice(2)}${Date.now().toString(36)}`;
      localStorage.setItem(DEVICE_KEY, id);
    }
    return id;
  },
  set(access: string, refresh: string): void {
    localStorage.setItem(ACCESS_KEY, access);
    localStorage.setItem(REFRESH_KEY, refresh);
  },
  clear(): void {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  },
};

/** Raw client without interceptors — used for auth calls (login/refresh). */
export const authApi: AxiosInstance = axios.create({ baseURL: API_URL });

/** Authenticated client with bearer token + transparent refresh on 401. */
export const api: AxiosInstance = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = tokenStore.access;
  if (token) {
    config.headers.set('Authorization', `Bearer ${token}`);
  }
  return config;
});

let refreshing: Promise<string | null> | null = null;

async function refreshTokens(): Promise<string | null> {
  const refresh = tokenStore.refresh;
  if (!refresh) return null;
  try {
    const { data } = await authApi.post<{ accessToken: string; refreshToken: string }>(
      '/auth/refresh',
      { refreshToken: refresh, deviceId: tokenStore.deviceId },
    );
    tokenStore.set(data.accessToken, data.refreshToken);
    return data.accessToken;
  } catch {
    tokenStore.clear();
    return null;
  }
}

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const original = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined;
    if (error.response?.status === 401 && original && !original._retry) {
      original._retry = true;
      refreshing = refreshing ?? refreshTokens();
      const newToken = await refreshing;
      refreshing = null;
      if (newToken) {
        original.headers.set('Authorization', `Bearer ${newToken}`);
        return api(original);
      }
      // Refresh failed — force the app back to the login screen.
      window.dispatchEvent(new CustomEvent('focaly:logout'));
    }
    return Promise.reject(error);
  },
);

export function apiErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as { message?: string; code?: string } | undefined;
    if (data?.message) return data.message;
    return error.message;
  }
  return 'Unexpected error';
}
