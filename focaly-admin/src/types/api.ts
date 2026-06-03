export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  pages: number;
}

export type Plan = 'free' | 'premium';
export type Role = 'user' | 'admin';

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  avatarUrl: string | null;
  emailVerified: boolean;
  role: Role;
  plan: Plan;
  premiumUntil: string | null;
  totalPoints: number;
  lastActiveAt: string | null;
  isDeleted: boolean;
  isBanned: boolean;
  bannedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface UserActivity {
  focusMinutes: number;
  completedCycles: number;
  plannedItemsCompleted: number;
}

export interface AdminUserDetail extends AdminUser {
  subscription: Subscription | null;
  streak: { current: number; longest: number; points: number } | null;
  activeSessions: number;
  activity: UserActivity;
}

export interface Subscription {
  id: string;
  userId: string;
  provider: string;
  status: string;
  currentPeriodEnd: string | null;
  priceId: string | null;
  lastEventAt: string | null;
  createdAt: string;
  updatedAt: string;
  user?: { email?: string; name?: string; plan?: Plan; premiumUntil?: string | null };
}

export interface PaymentEvent {
  id: string;
  provider: string;
  eventId: string;
  userId: string | null;
  outcome: string | null;
  error: string | null;
  createdAt: string;
}

export interface SubscriptionDetail {
  user: { email: string; name: string; plan: Plan; premiumUntil: string | null };
  subscription: Subscription | null;
  events: PaymentEvent[];
}

export interface RevenueSummary {
  activeSubscriptions: number;
  subscriptionsByStatus: Record<string, number>;
  subscriptionsByProvider: Record<string, number>;
  appliedPaymentsByProvider: Record<string, number>;
}

export interface AnalyticsOverview {
  users: {
    total: number;
    premium: number;
    free: number;
    banned: number;
    newLast30Days: number;
    dau: number;
    mau: number;
  };
  subscriptions: { active: number };
  ai: { jobs: number; tokensIn: number; tokensOut: number; totalTokens: number };
  engagement: { pomodoroSessions: number; focusMinutes: number; tasksCompleted: number };
}

export interface SignupSeries {
  from: string;
  to: string;
  series: Array<{ date: string; count: number }>;
}

export interface Session {
  id: string;
  deviceId: string;
  userAgent: string | null;
  ip: string | null;
  createdAt: string;
  expiresAt: string;
}

export interface SubjectItem {
  id: string;
  userId: string;
  name: string;
  color: string | null;
  progressPercent: number;
  isArchived: boolean;
  createdAt: string;
}

export interface PlannedItem {
  id: string;
  userId: string;
  kind: string;
  title: string;
  plannedAt: string;
  completed: boolean;
  createdAt: string;
}

export interface AiJob {
  id: string;
  userId: string;
  status: string;
  failureReason: string | null;
  tokensIn: number | null;
  tokensOut: number | null;
  createdAt: string;
}

export interface BroadcastRecord {
  title: string;
  body: string | null;
  type: string;
  recipients: number;
  sentAt: string;
}

export interface AiSettings {
  enabled: boolean;
  apiKeySet: boolean;
  apiKeyPreview: string | null;
  apiKeySource: 'database' | 'env' | 'none';
  model: string;
  temperature: number;
  systemPrompt: string | null;
  updatedAt: string | null;
}

export interface UpdateAiSettingsPayload {
  enabled?: boolean;
  apiKey?: string;
  model?: string;
  temperature?: number;
  systemPrompt?: string;
}

export interface AiTestResult {
  ok: boolean;
  model?: string;
  error?: string;
}
