import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { api } from '@/lib/api';
import type {
  AdminUser,
  AdminUserDetail,
  AiJob,
  AiSettings,
  AiTestResult,
  AnalyticsOverview,
  BroadcastRecord,
  Paginated,
  PlannedItem,
  PlatformSettings,
  RevenueSummary,
  Session,
  SignupSeries,
  SubjectItem,
  Subscription,
  SubscriptionDetail,
  UpdateAiSettingsPayload,
  UpdatePlatformSettingsPayload,
} from '@/types/api';

async function get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const { data } = await api.get<T>(url, { params });
  return data;
}

/* ----------------------------- Users ----------------------------- */

export interface UsersFilter {
  q?: string;
  plan?: string;
  role?: string;
  status?: string;
  page?: number;
}

export function useUsers(filter: UsersFilter) {
  return useQuery({
    queryKey: ['users', filter],
    queryFn: () => get<Paginated<AdminUser>>('/admin/users', { ...filter, limit: 20 }),
  });
}

export function useUser(id: string | undefined) {
  return useQuery({
    queryKey: ['user', id],
    enabled: Boolean(id),
    queryFn: () => get<AdminUserDetail>(`/admin/users/${id}`),
  });
}

export function useUserSessions(id: string | undefined) {
  return useQuery({
    queryKey: ['user-sessions', id],
    enabled: Boolean(id),
    queryFn: () => get<Session[]>(`/admin/users/${id}/sessions`),
  });
}

export interface UpdateUserPayload {
  name?: string;
  role?: string;
  plan?: string;
  emailVerified?: boolean;
  premiumUntil?: string | null;
}

export function useUpdateUser(id: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: UpdateUserPayload) =>
      api.patch(`/admin/users/${id}`, payload).then((r) => r.data),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['user', id] });
      void qc.invalidateQueries({ queryKey: ['users'] });
    },
  });
}

export function useUserAction(id: string) {
  const qc = useQueryClient();
  const invalidate = (): void => {
    void qc.invalidateQueries({ queryKey: ['user', id] });
    void qc.invalidateQueries({ queryKey: ['users'] });
    void qc.invalidateQueries({ queryKey: ['user-sessions', id] });
  };
  return {
    ban: useMutation({ mutationFn: () => api.post(`/admin/users/${id}/ban`), onSuccess: invalidate }),
    unban: useMutation({
      mutationFn: () => api.post(`/admin/users/${id}/unban`),
      onSuccess: invalidate,
    }),
    remove: useMutation({ mutationFn: () => api.delete(`/admin/users/${id}`), onSuccess: invalidate }),
    revokeSession: useMutation({
      mutationFn: (sessionId: string) => api.delete(`/admin/users/${id}/sessions/${sessionId}`),
      onSuccess: invalidate,
    }),
  };
}

/* ------------------------- Subscriptions ------------------------- */

export function useSubscriptions(filter: { status?: string; provider?: string; page?: number }) {
  return useQuery({
    queryKey: ['subscriptions', filter],
    queryFn: () => get<Paginated<Subscription>>('/admin/subscriptions', { ...filter, limit: 20 }),
  });
}

export function useSubscriptionDetail(userId: string | undefined) {
  return useQuery({
    queryKey: ['subscription', userId],
    enabled: Boolean(userId),
    queryFn: () => get<SubscriptionDetail>(`/admin/subscriptions/${userId}`),
  });
}

export function useRevenue() {
  return useQuery({
    queryKey: ['revenue'],
    queryFn: () => get<RevenueSummary>('/admin/subscriptions/revenue/summary'),
  });
}

export function useSubscriptionActions() {
  const qc = useQueryClient();
  const invalidate = (): void => {
    void qc.invalidateQueries({ queryKey: ['subscriptions'] });
    void qc.invalidateQueries({ queryKey: ['revenue'] });
    void qc.invalidateQueries({ queryKey: ['user'] });
  };
  return {
    extend: useMutation({
      mutationFn: (vars: { userId: string; days: number }) =>
        api.post(`/admin/subscriptions/${vars.userId}/extend`, { days: vars.days }),
      onSuccess: invalidate,
    }),
    cancel: useMutation({
      mutationFn: (userId: string) => api.post(`/admin/subscriptions/${userId}/cancel`),
      onSuccess: invalidate,
    }),
  };
}

/* --------------------------- Analytics --------------------------- */

export function useOverview() {
  return useQuery({
    queryKey: ['overview'],
    queryFn: () => get<AnalyticsOverview>('/admin/analytics/overview'),
  });
}

export function useSignups() {
  return useQuery({
    queryKey: ['signups'],
    queryFn: () => get<SignupSeries>('/admin/analytics/signups'),
  });
}

/* ------------------------- Notifications ------------------------- */

export interface BroadcastPayload {
  title: string;
  body?: string;
  type?: string;
  target: string;
  userIds?: string[];
  push?: boolean;
}

export function useBroadcasts() {
  return useQuery({
    queryKey: ['broadcasts'],
    queryFn: () => get<BroadcastRecord[]>('/admin/notifications/broadcasts'),
  });
}

export function useSendBroadcast() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: BroadcastPayload) =>
      api
        .post<{ recipients: number; pushed: number }>('/admin/notifications/broadcast', payload)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['broadcasts'] }),
  });
}

/* ---------------------------- Content ---------------------------- */

export function useSubjects(page: number) {
  return useQuery({
    queryKey: ['content-subjects', page],
    queryFn: () => get<Paginated<SubjectItem>>('/admin/content/subjects', { page, limit: 20 }),
  });
}

export function usePlannedItems(page: number, kind?: string) {
  return useQuery({
    queryKey: ['content-items', page, kind],
    queryFn: () =>
      get<Paginated<PlannedItem>>('/admin/content/planned-items', { page, kind, limit: 20 }),
  });
}

export function useAiJobs(page: number, status?: string) {
  return useQuery({
    queryKey: ['content-aijobs', page, status],
    queryFn: () => get<Paginated<AiJob>>('/admin/content/ai-jobs', { page, status, limit: 20 }),
  });
}

/* -------------------------- AI settings -------------------------- */

export function useAiSettings() {
  return useQuery({
    queryKey: ['ai-settings'],
    queryFn: () => get<AiSettings>('/admin/ai/settings'),
  });
}

export function useUpdateAiSettings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: UpdateAiSettingsPayload) =>
      api.patch<AiSettings>('/admin/ai/settings', payload).then((r) => r.data),
    onSuccess: (data) => qc.setQueryData(['ai-settings'], data),
  });
}

export function useTestAiConnection() {
  return useMutation({
    mutationFn: (apiKey?: string) =>
      api.post<AiTestResult>('/admin/ai/test', { apiKey }).then((r) => r.data),
  });
}

/* ----------------------- Platform settings ----------------------- */

export function usePlatformSettings() {
  return useQuery({
    queryKey: ['platform-settings'],
    queryFn: () => get<PlatformSettings>('/admin/platform/settings'),
  });
}

export function useUpdatePlatformSettings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: UpdatePlatformSettingsPayload) =>
      api.patch<PlatformSettings>('/admin/platform/settings', payload).then((r) => r.data),
    onSuccess: (data) => qc.setQueryData(['platform-settings'], data),
  });
}
