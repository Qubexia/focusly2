# Focaly — Study Management Mobile App — Backend Architecture

## Context

This document defines the **production-grade backend architecture** for **Focaly**, a Study Management Mobile App. The backend powers a mobile client that helps students organize subjects, study schedules, pomodoro sessions, streaks, lectures, revisions, exams, and tasks — plus premium features (analytics, focus mode, AI notes assistant, unlimited subjects).

**Stack:** NestJS (TypeScript) · MongoDB + Mongoose · Redis · BullMQ · Firebase Cloud Messaging · Swagger · JWT · Clean & Modular Architecture · Render / AWS deployment (no Docker).

**Intended outcome:** a senior-level, modular, clean-architecture backend that is deployment-ready, fully Swagger-documented, secure, observable, and scalable from MVP to SaaS.

---

## 1. System Architecture

### 1.1 Monolith vs Microservices — Decision

**Decision: Modular Monolith** (single deployable, strict module boundaries).

| Criterion | Monolith | Microservices |
|---|---|---|
| Team size at MVP | ✅ small | ❌ overkill |
| Feature coupling (subject ↔ schedule ↔ streak) | ✅ shared models | ❌ chatty network |
| Deployment cost | ✅ 1 service | ❌ 8+ services |
| Future split | ✅ easy via module borders | — |

**Carve out later as workers** (not full microservices) when load demands:
- `notifications-worker` (BullMQ consumer for FCM)
- `ai-worker` (OpenAI / OCR heavy jobs)
- `analytics-worker` (aggregation pipelines, cron rollups)

### 1.2 Clean Architecture Layers

Each feature module follows 4 layers:

```
┌─────────────────────────────────────────────────┐
│  Presentation   →  Controllers, DTOs, Swagger   │
│  Application    →  Services, Use-Cases, Mappers │
│  Domain         →  Entities, Value Objects, Interfaces (ports) │
│  Infrastructure →  Mongoose Schemas, Repos, FCM client, OpenAI client │
└─────────────────────────────────────────────────┘
```

**Rule:** Domain knows nothing. Application depends on Domain only. Infrastructure implements Domain ports. Presentation depends on Application.

### 1.3 Folder Structure

```
focaly-backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── config/                       # @nestjs/config + Joi validation
│   │   ├── configuration.ts
│   │   ├── validation.schema.ts
│   │   └── env/
│   │       ├── app.config.ts
│   │       ├── db.config.ts
│   │       ├── redis.config.ts
│   │       ├── jwt.config.ts
│   │       ├── fcm.config.ts
│   │       ├── openai.config.ts
│   │       └── stripe.config.ts
│   │
│   ├── common/                       # cross-cutting
│   │   ├── decorators/               # @CurrentUser, @Public, @Roles, @Premium
│   │   ├── filters/                  # AllExceptionsFilter, MongoExceptionFilter
│   │   ├── interceptors/             # LoggingInterceptor, TransformInterceptor, CacheInterceptor
│   │   ├── pipes/                    # ParseObjectIdPipe, ValidationPipe
│   │   ├── guards/                   # JwtAuthGuard, RolesGuard, PremiumGuard, ThrottlerBehindProxyGuard
│   │   ├── middleware/               # RequestIdMiddleware, AuditLogMiddleware
│   │   ├── dto/                      # PaginationDto, DateRangeDto, ApiResponse
│   │   ├── utils/                    # date, hash, ids
│   │   └── constants/
│   │
│   ├── modules/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── subjects/
│   │   ├── study-schedules/
│   │   ├── pomodoro/
│   │   ├── streaks/
│   │   ├── tasks/
│   │   ├── revisions/
│   │   ├── lectures/
│   │   ├── exams/
│   │   ├── notifications/
│   │   ├── analytics/
│   │   ├── subscription/
│   │   ├── ai/
│   │   ├── uploads/
│   │   └── health/
│   │
│   ├── infrastructure/
│   │   ├── database/                 # mongoose root module, migrations
│   │   ├── redis/
│   │   ├── queue/                    # BullMQ shared
│   │   ├── fcm/                      # firebase-admin client
│   │   ├── storage/                  # S3 client
│   │   ├── mailer/                   # nodemailer / SES
│   │   ├── logger/                   # pino
│   │   └── tracing/                  # OpenTelemetry
│   │
│   └── shared/
│       ├── events/                   # EventBus (Nest CQRS) — internal events
│       └── types/
│
├── test/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
│
├── scripts/
│   ├── seed.ts
│   └── migrate.ts
│
├── docs/
│   ├── architecture.md               # this file
│   └── openapi.json                  # exported in CI
│
├── .env.example
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
├── package.json
├── README.md
└── render.yaml
```

### 1.4 Module dependency map (one-way only)

```
auth ─┐
users ┴── subjects ──┬── study-schedules
                     ├── pomodoro ──── streaks ─── tasks
                     ├── lectures
                     ├── revisions
                     ├── exams
                     └── ai
notifications ◄── (consumer of events from all above)
analytics     ◄── (consumer of events)
subscription  ◄── PremiumGuard used by subjects/ai/analytics
```

Modules communicate via **NestJS EventBus** (`@nestjs/cqrs`) for fan-out (e.g., `PomodoroCompletedEvent` → streaks + analytics + notifications).

---

## 2. Database Design (MongoDB + Mongoose)

### 2.1 Collections overview

| Collection | Purpose | Key indexes |
|---|---|---|
| `users` | profile, auth | `email` unique, `googleId` sparse |
| `auth_sessions` | refresh tokens / devices | `userId+deviceId`, TTL on `expiresAt` |
| `subjects` | per-user subjects | `userId+isArchived`, text on `name` |
| `study_schedules` | weekly schedule items | `userId+startAt`, `subjectId` |
| `pomodoro_sessions` | completed/ongoing sessions | `userId+startedAt`, `subjectId+startedAt` |
| `streaks` | one doc per user | `userId` unique |
| `tasks` | daily/weekly tasks | `userId+dueAt`, `subjectId` |
| `revisions` | revision schedule | `userId+plannedAt` |
| `lectures` | class schedule | `userId+startAt` |
| `exams` | exam schedule | `userId+date` |
| `chapters` | lessons inside subject | `subjectId+order` |
| `notifications` | inbox + audit | `userId+createdAt`, TTL 90d |
| `notification_jobs` | scheduled FCM | `scheduledAt`, `status` |
| `subscriptions` | premium state | `userId` unique, `provider+providerSubId` |
| `payment_events` | webhook log | `provider+eventId` unique |
| `ai_jobs` | image → notes pipeline | `userId+status` |
| `ai_artifacts` | summaries, flashcards | `userId+subjectId` |
| `audit_logs` | security events | `userId+createdAt`, TTL 365d |
| `rate_limits` | sliding-window store | TTL on `expiresAt` |

### 2.2 Core Mongoose schemas (TypeScript)

```ts
// users
@Schema({ timestamps: true })
class User {
  @Prop({ required: true, lowercase: true, index: true, unique: true })
  email: string;

  @Prop() passwordHash?: string;        // null when Google-only
  @Prop({ index: true, sparse: true }) googleId?: string;
  @Prop() name: string;
  @Prop() avatarUrl?: string;
  @Prop({ default: false }) emailVerified: boolean;
  @Prop({ enum: ['user','admin'], default: 'user' }) role: string;
  @Prop({ default: 'free', enum: ['free','premium'] }) plan: 'free'|'premium';
  @Prop() premiumUntil?: Date;
  @Prop({ type: Object }) settings: {
    locale: string;
    timezone: string;
    focusMode: boolean;
    notifications: { reminders: boolean; streak: boolean; marketing: boolean };
  };
  @Prop({ default: 0 }) totalPoints: number;
  @Prop() lastActiveAt?: Date;
  @Prop({ default: false }) isDeleted: boolean;
}
```

```ts
// subjects
@Schema({ timestamps: true })
class Subject {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  userId: Types.ObjectId;
  @Prop({ required: true, trim: true }) name: string;
  @Prop() color?: string;
  @Prop() icon?: string;
  @Prop({ default: 0 }) dailyTargetMinutes: number;
  @Prop({ default: 0 }) progressPercent: number;
  @Prop({ default: false, index: true }) isArchived: boolean;
}
SubjectSchema.index({ userId: 1, isArchived: 1 });
SubjectSchema.index({ name: 'text' });
```

```ts
// study_schedules (recurring weekly)
@Schema({ timestamps: true })
class StudySchedule {
  @Prop({ type: Types.ObjectId, ref: 'User', index: true }) userId;
  @Prop({ type: Types.ObjectId, ref: 'Subject', index: true }) subjectId;
  @Prop({ required: true }) title: string;
  @Prop({ required: true, index: true }) startAt: Date;   // first occurrence
  @Prop() endAt: Date;
  @Prop({ type: [Number] }) daysOfWeek: number[];         // 0..6
  @Prop() rrule?: string;                                  // RFC5545 for advanced
  @Prop({ default: 15 }) reminderMinutesBefore: number;
  @Prop({ default: true }) reminderEnabled: boolean;
  @Prop({ default: true }) isActive: boolean;
}
```

```ts
// pomodoro_sessions
@Schema({ timestamps: true })
class PomodoroSession {
  @Prop({ index: true }) userId;
  @Prop({ index: true }) subjectId?;
  @Prop({ required: true }) startedAt: Date;
  @Prop() endedAt?: Date;
  @Prop({ default: 25 }) focusMinutes: number;
  @Prop({ default: 5 }) breakMinutes: number;
  @Prop({ default: 0 }) completedCycles: number;
  @Prop({ default: 0 }) totalFocusMinutes: number;
  @Prop({ enum: ['active','paused','completed','aborted'] }) status: string;
}
PomodoroSessionSchema.index({ userId: 1, startedAt: -1 });
```

```ts
// streaks
@Schema({ timestamps: true })
class Streak {
  @Prop({ unique: true }) userId;
  @Prop({ default: 0 }) current: number;
  @Prop({ default: 0 }) longest: number;
  @Prop() lastActiveDate?: Date;          // user TZ-local date (yyyy-mm-dd)
  @Prop({ default: 0 }) points: number;
  @Prop({ type: [Object] }) rewards: { code: string; awardedAt: Date }[];
}
```

```ts
// chapters
@Schema({ timestamps: true })
class Chapter {
  @Prop({ index: true }) subjectId;
  @Prop({ index: true }) userId;
  @Prop({ required: true }) title: string;
  @Prop({ default: 0 }) order: number;
  @Prop({ default: false }) completed: boolean;
  @Prop() completedAt?: Date;
}
```

```ts
// tasks / revisions / lectures / exams — share a base shape
@Schema({ timestamps: true, discriminatorKey: 'kind' })
class PlannedItem {
  @Prop({ index: true }) userId;
  @Prop({ index: true }) subjectId?;
  @Prop({ enum: ['task','revision','lecture','exam'], required: true, index: true })
  kind: string;
  @Prop({ required: true }) title: string;
  @Prop() notes?: string;
  @Prop({ required: true, index: true }) plannedAt: Date;
  @Prop() durationMinutes?: number;
  @Prop({ enum: ['daily','weekly','once'] }) recurrence?: string;
  @Prop({ default: 15 }) reminderMinutesBefore: number;
  @Prop({ default: false }) completed: boolean;
  @Prop() completedAt?: Date;
  @Prop({ default: 0 }) rewardPoints: number;
}
```

```ts
// notifications (inbox)
@Schema({ timestamps: true })
class Notification {
  @Prop({ index: true }) userId;
  @Prop({ required: true }) type: string;      // 'reminder','streak','reward','system'
  @Prop({ required: true }) title: string;
  @Prop() body: string;
  @Prop({ type: Object }) data: Record<string, any>;
  @Prop({ default: false }) read: boolean;
  @Prop({ default: () => new Date(Date.now() + 90 * 864e5) }) expiresAt: Date;
}
NotificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });   // TTL
```

```ts
// notification_jobs (scheduling table — single source of truth)
@Schema({ timestamps: true })
class NotificationJob {
  @Prop({ index: true }) userId;
  @Prop({ required: true }) refType: string;   // 'study_schedule','exam','revision'…
  @Prop({ required: true }) refId: Types.ObjectId;
  @Prop({ required: true, index: true }) scheduledAt: Date;
  @Prop({ enum: ['pending','queued','sent','failed','cancelled'], default: 'pending', index: true })
  status: string;
  @Prop({ default: 0 }) attempts: number;
  @Prop() lastError?: string;
}
```

```ts
// subscriptions
@Schema({ timestamps: true })
class Subscription {
  @Prop({ unique: true }) userId;
  @Prop({ enum: ['stripe','google_play','app_store'], required: true }) provider;
  @Prop({ required: true }) providerSubId: string;
  @Prop({ enum: ['active','past_due','canceled','expired','trialing'] }) status;
  @Prop() currentPeriodEnd: Date;
  @Prop() priceId: string;
}
SubscriptionSchema.index({ provider: 1, providerSubId: 1 }, { unique: true });
```

```ts
// auth_sessions (refresh-token store)
@Schema({ timestamps: true })
class AuthSession {
  @Prop({ index: true }) userId;
  @Prop({ required: true }) deviceId: string;
  @Prop({ required: true }) refreshTokenHash: string;
  @Prop() userAgent?: string;
  @Prop() ip?: string;
  @Prop() fcmToken?: string;
  @Prop({ required: true }) expiresAt: Date;
  @Prop() revokedAt?: Date;
}
AuthSessionSchema.index({ userId: 1, deviceId: 1 }, { unique: true });
AuthSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

### 2.3 Relationships (ERD summary)

```
User 1───* Subject 1───* Chapter
User 1───* StudySchedule *───1 Subject
User 1───* PlannedItem  *───1 Subject     (task | revision | lecture | exam via discriminator)
User 1───1 Streak
User 1───* PomodoroSession *───1 Subject
User 1───* Notification
User 1───* NotificationJob
User 1───1 Subscription
User 1───* AuthSession
User 1───* AiJob 1───* AiArtifact
```

### 2.4 Indexing strategy

- **Compound:** every `userId + <sort/filter field>` pair.
- **TTL:** `auth_sessions.expiresAt`, `notifications.expiresAt`, `audit_logs.createdAt` (1y).
- **Text:** `subjects.name`, `chapters.title` for search.
- **Sparse:** `users.googleId`.
- **Unique:** `users.email`, `streaks.userId`, `subscriptions.{provider,providerSubId}`.

### 2.5 Example documents

```json
// subject
{
  "_id": "65f...",
  "userId": "65a...",
  "name": "Organic Chemistry",
  "color": "#FFB020",
  "dailyTargetMinutes": 60,
  "progressPercent": 42,
  "isArchived": false
}
```

```json
// pomodoro_session (completed)
{
  "userId": "65a...",
  "subjectId": "65f...",
  "startedAt": "2026-05-14T15:00:00Z",
  "endedAt": "2026-05-14T16:30:00Z",
  "focusMinutes": 25,
  "breakMinutes": 5,
  "completedCycles": 3,
  "totalFocusMinutes": 75,
  "status": "completed"
}
```

---

## 3. Modules — complete list

| # | Module | Premium-gated? |
|---|---|---|
| 1 | `auth` | — |
| 2 | `users` | — |
| 3 | `subjects` | partial (3-cap on free) |
| 4 | `study-schedules` | — |
| 5 | `pomodoro` | — |
| 6 | `streaks` | — |
| 7 | `tasks` | — |
| 8 | `revisions` | — |
| 9 | `lectures` | — |
| 10 | `exams` | — |
| 11 | `notifications` | — |
| 12 | `analytics` | ✅ |
| 13 | `subscription` | — |
| 14 | `ai` | ✅ |
| 15 | `uploads` | partial |
| 16 | `health` | — |

---

## 4. Module Specs (detailed)

> Each module ships with: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `dto/`, `schemas/`, `events/`, `*.spec.ts`. All controllers documented in Swagger via `@ApiTags`, `@ApiOperation`, `@ApiResponse`.

### 4.1 `auth`

**Responsibilities:** registration, login (email/Google), email verification, password reset, JWT access+refresh, session/device management, logout (single device + all devices).

**DTOs**
- `RegisterDto { email, password, name }`
- `LoginDto { email, password, deviceId, fcmToken? }`
- `GoogleLoginDto { idToken, deviceId, fcmToken? }`
- `RefreshDto { refreshToken, deviceId }`
- `ForgotPasswordDto { email }`
- `ResetPasswordDto { token, newPassword }`
- `VerifyEmailDto { token }`

**Endpoints**

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/auth/register` | public | create user, send verification email |
| POST | `/auth/login` | public | returns access + refresh + user |
| POST | `/auth/google` | public | verify Google id_token, upsert user |
| POST | `/auth/refresh` | public (refresh token) | rotate access+refresh |
| POST | `/auth/logout` | bearer | revoke current session |
| POST | `/auth/logout-all` | bearer | revoke all sessions |
| POST | `/auth/forgot-password` | public | email reset link |
| POST | `/auth/reset-password` | public | apply new password |
| POST | `/auth/verify-email` | public | mark email verified |
| GET | `/auth/sessions` | bearer | list active devices |
| DELETE | `/auth/sessions/:id` | bearer | revoke specific device |

**Guards:** `JwtAuthGuard` (default global), `@Public()` to skip. `JwtRefreshGuard` separate strategy for `/refresh`.

**Example response — login**
```json
{
  "user": { "id": "65a...", "email": "...", "plan": "free" },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "accessExpiresIn": 900,
    "refreshExpiresIn": 2592000
  }
}
```

### 4.2 `users`

Profile, settings, account deletion (soft + GDPR purge worker), avatar upload.

| Method | Path | Notes |
|---|---|---|
| GET | `/users/me` | profile + plan |
| PATCH | `/users/me` | name, locale, timezone |
| PATCH | `/users/me/settings` | focusMode, notification toggles |
| POST | `/users/me/avatar` | multipart → S3 |
| DELETE | `/users/me` | soft delete, schedule purge |
| POST | `/users/me/fcm-token` | register device token |

### 4.3 `subjects`

**Free-plan guard:** before insert, count subjects where `userId=current && isArchived=false`. If `plan==='free' && count>=3` → `403 SUBJECT_LIMIT_REACHED`.

| Method | Path |
|---|---|
| GET | `/subjects` |
| POST | `/subjects` |
| GET | `/subjects/:id` |
| PATCH | `/subjects/:id` |
| DELETE | `/subjects/:id` (soft archive) |
| POST | `/subjects/:id/chapters` |
| PATCH | `/subjects/:id/chapters/:chId` |
| GET | `/subjects/:id/progress` |

`progressPercent` recomputed via `@OnEvent('chapter.completed')`.

### 4.4 `study-schedules`

Recurring weekly items with reminder offset. On create/update: emit `ScheduleChangedEvent` → notifications module recomputes upcoming reminder jobs (next 14 days window).

| Method | Path |
|---|---|
| POST | `/subjects/:id/schedules` |
| GET | `/schedules?from=&to=` |
| PATCH | `/schedules/:id` |
| DELETE | `/schedules/:id` |
| GET | `/schedules/calendar?range=week` |

### 4.5 `pomodoro`

| Method | Path | Body |
|---|---|---|
| POST | `/pomodoro/start` | `{ subjectId?, focusMinutes?, breakMinutes? }` |
| POST | `/pomodoro/:id/pause` | — |
| POST | `/pomodoro/:id/resume` | — |
| POST | `/pomodoro/:id/complete` | `{ cycles }` |
| POST | `/pomodoro/:id/abort` | — |
| GET | `/pomodoro/today` | total focus minutes |
| GET | `/pomodoro/history?from=&to=` | paginated |

On `complete` → emit `PomodoroCompletedEvent { userId, subjectId, totalFocusMinutes }` → consumed by:
- `streaks` (advance/maintain streak)
- `analytics` (update aggregates)
- `users` (add points)

### 4.6 `streaks`

Pure service, no public CRUD beyond read.

| Method | Path |
|---|---|
| GET | `/streaks/me` | current, longest, points, rewards |
| GET | `/streaks/leaderboard?scope=friends` | v2 |

Internal logic:
- `current++` if last activity = yesterday (user TZ).
- reset to 0 if gap > 1 day at daily cron.
- reward thresholds (3, 7, 30, 100 days) → push points + notification.

Daily cron `0 3 * * *` UTC → fan out per timezone bucket.

### 4.7 `tasks` / `revisions` / `lectures` / `exams`

All use the `PlannedItem` discriminator. Same controller shape per `kind`:

| Method | Path |
|---|---|
| POST | `/{kind}` |
| GET | `/{kind}?from=&to=&subjectId=` |
| GET | `/{kind}/:id` |
| PATCH | `/{kind}/:id` |
| POST | `/{kind}/:id/complete` |
| DELETE | `/{kind}/:id` |

Completion triggers reward points (configurable per kind) and updates streaks.

### 4.8 `notifications`

Two surfaces: **inbox** (DB-backed) and **push** (FCM).

| Method | Path |
|---|---|
| GET | `/notifications?unreadOnly=` |
| PATCH | `/notifications/:id/read` |
| POST | `/notifications/read-all` |
| DELETE | `/notifications/:id` |
| GET | `/notifications/preferences` |
| PATCH | `/notifications/preferences` |

See §6 for the scheduler.

### 4.9 `analytics` (premium)

Aggregation pipelines (no per-record reads on the API).

| Method | Path | Returns |
|---|---|---|
| GET | `/analytics/summary?from=&to=` | total study minutes, sessions, tasks completed |
| GET | `/analytics/by-subject?from=&to=` | per-subject breakdown |
| GET | `/analytics/heatmap?year=` | day-by-day minutes |
| GET | `/analytics/performance?from=&to=` | completion rate, streak retention |

Backed by daily rollups (`analytics_daily` materialized collection) populated by a `0 1 * * *` cron.

### 4.10 `subscription`

| Method | Path |
|---|---|
| GET | `/subscription/me` |
| POST | `/subscription/stripe/checkout` | returns Checkout URL |
| POST | `/subscription/stripe/portal` | manage |
| POST | `/subscription/webhook/stripe` | raw body, signature verified |
| POST | `/subscription/iap/google/verify` | purchase token |
| POST | `/subscription/iap/apple/verify` | receipt |
| POST | `/subscription/cancel` | mark cancel-at-period-end |

### 4.11 `ai` (premium)

| Method | Path | Body |
|---|---|---|
| POST | `/ai/notes/jobs` | `{ subjectId, imageUrls[] }` → returns `jobId` |
| GET | `/ai/notes/jobs/:id` | status + artifacts |
| POST | `/ai/flashcards` | `{ subjectId, text }` |
| POST | `/ai/questions` | `{ subjectId, text }` |
| GET | `/ai/artifacts?subjectId=` | list |

See §8.

### 4.12 `uploads`

Presigned S3 PUT URLs only; the API never proxies file bytes.

| Method | Path |
|---|---|
| POST | `/uploads/presign` | `{ kind:'avatar'|'lecture-image', mimeType, sizeBytes }` |
| POST | `/uploads/confirm` | finalize record |

### 4.13 `health`

`GET /health` (liveness), `GET /health/ready` (Mongo + Redis + Stripe + FCM pings).

---

## 5. Authentication System

### 5.1 JWT design

| Token | Lifetime | Storage (client) | Claims |
|---|---|---|---|
| Access | 15 min | secure storage (Keychain/Keystore) | `sub, plan, role, sid` |
| Refresh | 30 days, rotating | secure storage | `sub, sid, jti` |

- **Rotation:** every refresh issues a new pair and **invalidates the previous `jti`** (stored hashed in `auth_sessions`).
- **Theft detection:** if a refresh is presented twice → revoke entire family + force re-login.
- **Signing:** RS256 with key pair stored in env (`JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`), rotated quarterly.

### 5.2 Google OAuth

Mobile-driven: client obtains Google `idToken` → backend verifies via `google-auth-library` (`audience: GOOGLE_CLIENT_ID`) → upsert user by `googleId` or merge by verified email.

### 5.3 Email verification & password reset

- Tokens are short JWTs (30 min) signed with a separate secret, single-use (jti stored in Redis with TTL).
- Email delivery via SES/SendGrid (Mailer module).

### 5.4 Session & device management

- One `AuthSession` per `(userId, deviceId)`.
- Stores `fcmToken` so push targets the right device.
- `/auth/sessions` lists active devices; `DELETE /auth/sessions/:id` revokes and clears FCM token.

---

## 6. Notification System

### 6.1 Stack

`@nestjs/bullmq` (Redis) + `firebase-admin` + Mongo `notification_jobs` table.

### 6.2 Flow

```
[create/edit schedule|task|exam]
        ↓ emit event
[Notifications service]
        ↓ compute send-at = plannedAt - reminderMinutesBefore
[Mongo: notification_jobs row created]
        ↓
[BullMQ delayed job (delay = send-at - now)]
        ↓
[FCM worker] → multicast to user's device tokens
        ↓
[on success] mark job 'sent' + write Notification (inbox) row
[on failure] retry w/ exp backoff; mark 'failed' after N
```

Why both Mongo and BullMQ? — **Mongo is the source of truth** (survives Redis flush, supports timezone re-computation on user TZ change). BullMQ is just the dispatcher.

### 6.3 Queues

| Queue | Job types | Concurrency |
|---|---|---|
| `notifications` | `send.push`, `send.email` | 10 |
| `ai` | `notes.process` | 2 |
| `analytics` | `daily.rollup` | 1 |
| `subscription` | `iap.recheck` | 5 |
| `maintenance` | `streak.reset`, `cleanup.expired` | 1 |

### 6.4 Cron jobs (`@nestjs/schedule`)

| Cron | Purpose |
|---|---|
| `*/5 * * * *` | enqueue jobs whose `scheduledAt` within next 10 min and not queued |
| `0 1 * * *` | analytics daily rollup |
| `0 3 * * *` | streak maintenance (per TZ bucket) |
| `0 4 * * *` | cleanup expired tokens, soft-deleted users (after 30d) |
| `0 */6 * * *` | IAP receipt re-validation |

### 6.5 Retry strategy

BullMQ: `attempts: 5, backoff: { type: 'exponential', delay: 30_000 }`. Dead-lettered jobs surface to admin dashboard (`bull-board`).

### 6.6 Notification preferences

Per-category toggles on `User.settings.notifications`. Worker checks before dispatch. **Focus Mode** suppresses non-critical pushes if `focusMode === true` AND user has an `active` pomodoro session.

---

## 7. Premium Subscription System

### 7.1 Feature matrix

| Feature | Free | Premium |
|---|---|---|
| Subjects | 3 | ∞ |
| Pomodoro | ✅ | ✅ |
| Schedules / tasks / reminders | ✅ | ✅ |
| Ads | shown | removed |
| Focus Mode | ❌ | ✅ |
| Analytics | basic (this week) | full (date-range, charts) |
| AI Notes Assistant | ❌ | ✅ |

### 7.2 `PremiumGuard`

```ts
@Injectable()
export class PremiumGuard implements CanActivate {
  canActivate(ctx: ExecutionContext) {
    const req = ctx.switchToHttp().getRequest();
    const user = req.user;
    if (user.plan === 'premium' && (!user.premiumUntil || user.premiumUntil > new Date()))
      return true;
    throw new ForbiddenException({ code: 'PREMIUM_REQUIRED' });
  }
}
```

Used as `@UseGuards(JwtAuthGuard, PremiumGuard)` on AI/Analytics/Focus endpoints.

### 7.3 Providers

- **Stripe** (web/admin): Checkout + Customer Portal + webhook (`checkout.session.completed`, `customer.subscription.updated/deleted`, `invoice.payment_failed`).
- **Google Play Billing**: purchase token verified via Play Developer API; subscription notifications via Pub/Sub → webhook.
- **App Store**: receipt verification via App Store Server API + server notifications v2 webhook.

All three converge to the single `subscriptions` collection. `User.plan`/`premiumUntil` are mirrored for fast access checks; webhooks are the source of truth.

### 7.4 Idempotency

Webhook handler stores each `eventId` in `payment_events` with a unique index — duplicate deliveries become no-ops.

---

## 8. AI Module Architecture

### 8.1 Flow

```
Mobile uploads images → S3 (via presigned PUT)
   │
   ▼
POST /ai/notes/jobs {subjectId, imageKeys[]}
   │  creates AiJob{status:'queued'}
   ▼
BullMQ ai-queue
   │
   ▼ ai-worker:
     1. download images from S3
     2. OCR  (AWS Textract preferred; fallback: Tesseract or Google Vision)
     3. compose prompt with extracted text
     4. OpenAI Responses API (gpt-4o-mini for cost; gpt-4o for hard cases)
        →  summary, simplified explanation
     5. second call → flashcards (Q/A pairs, JSON-mode)
     6. third call → important questions (JSON-mode)
     7. persist AiArtifact rows, mark job 'completed'
     8. emit AiJobCompletedEvent → push notification
```

### 8.2 OCR recommendation

**AWS Textract** for handwriting + tables (best quality on lecture notes). Tesseract only as a local-dev fallback. Cache OCR result by image SHA-256 to avoid re-billing on retries.

### 8.3 Cost optimization

- **Prompt caching** via OpenAI cache headers; reuse system prompt across the three calls.
- Truncate OCR text to top-K paragraphs (token budget).
- Use `gpt-4o-mini` by default; escalate only if `confidence<0.6`.
- Hard per-user monthly cap (e.g., 30 jobs) tracked in `ai_jobs` count — return `429` past the cap.

### 8.4 Rate limiting

- Per-user: 5 jobs / hour, 30 / day (Redis sliding window).
- Per-IP: 60 / hour at gateway (Throttler).
- Concurrency in worker: 2 — protects OpenAI quota.

### 8.5 JSON-mode contracts

```ts
// flashcards
{ cards: [{ front: string, back: string, tag?: string }] }

// questions
{ questions: [{ q: string, difficulty: 'easy'|'medium'|'hard', topic?: string }] }
```

Validated with `zod` before persisting.

---

## 9. Analytics System

### 9.1 Approach

Hybrid: **on-write counters** (cheap dashboards) + **aggregation pipelines** (rich queries) + **daily rollups** (heatmap, long ranges).

### 9.2 Aggregation pipeline example — minutes per subject in range

```ts
db.pomodoro_sessions.aggregate([
  { $match: { userId, status: 'completed', startedAt: { $gte: from, $lt: to } } },
  { $group: { _id: '$subjectId', minutes: { $sum: '$totalFocusMinutes' }, sessions: { $sum: 1 } } },
  { $lookup: { from: 'subjects', localField: '_id', foreignField: '_id', as: 's' } },
  { $project: { subjectId: '$_id', name: { $first: '$s.name' }, minutes: 1, sessions: 1, _id: 0 } },
  { $sort: { minutes: -1 } }
]);
```

### 9.3 Daily rollup schema

```ts
@Schema()
class AnalyticsDaily {
  userId; date: string /* yyyy-mm-dd */;
  totalFocusMinutes: number;
  sessions: number;
  tasksCompleted: number;
  perSubject: Record<string, number>;
}
```

Indexed on `{ userId: 1, date: -1 }`. Heatmap = one indexed scan.

### 9.4 Charts-ready response

```json
{
  "range": { "from": "2026-04-01", "to": "2026-05-14" },
  "series": [
    { "date": "2026-04-01", "minutes": 65, "tasks": 3 }
  ],
  "totals": { "minutes": 3200, "tasks": 84, "sessions": 120 }
}
```

---

## 10. Security Best Practices

| Concern | Mitigation |
|---|---|
| HTTP headers | `helmet` with strict CSP for any web admin |
| CORS | allowlist mobile origins + admin domain |
| Rate limit | `@nestjs/throttler` (Redis store) + per-endpoint overrides; aggressive on `/auth/*` (10/min/IP) and `/ai/*` |
| Input validation | global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` + `class-validator` |
| Mongo injection | DTO transform forbids non-whitelisted; never pass raw `$` operators |
| Password hashing | `argon2id`, memoryCost 64MB |
| JWT | RS256, short access, rotating refresh, jti revocation |
| Secrets | AWS Secrets Manager / Render secret env |
| File uploads | presigned PUT, content-type & size enforced server-side via presign policy; antivirus lambda on bucket (optional) |
| Audit logs | every auth event, plan change, admin action → `audit_logs` (1y TTL) |
| Logging hygiene | `pino` with redact paths (`req.headers.authorization`, `*.password`, `*.refreshToken`) |
| Dependency safety | `npm audit` + Snyk in CI; Renovate bot |
| OWASP API top 10 | covered via guards + validation + rate limits + audit |

---

## 11. Performance Optimization

| Layer | Strategy |
|---|---|
| Redis | cache `users/me`, subject list, subscription state (60s TTL with invalidation hooks) |
| Mongo | compound indexes (§2.4); `lean()` for read-only queries; `select()` to limit fields |
| Pagination | cursor-based for history-heavy endpoints (pomodoro, notifications); page+limit for small lists |
| Queue | offload all non-critical work to BullMQ (push, AI, rollups) |
| N+1 | single `$lookup` aggregations instead of per-doc populates |
| Connection pool | Mongoose `maxPoolSize: 50` (tune per instance) |
| Horizontal scaling | stateless API (sticky session not required); Redis-backed Throttler; sessions in Mongo not memory |
| HTTP | `compression`, Brotli on CDN |
| Cold-path GC | TTL indexes on notifications, audit_logs, auth_sessions |

---

## 12. DevOps & Deployment

> **Note:** No Docker / no containerization. Deployment uses Render's native Node runtime (and AWS Elastic Beanstalk Node platform when scaling up).

### 12.1 Local development

- Run Mongo + Redis as **local installations** (Windows installers) or use **MongoDB Atlas + Upstash Redis** free tiers (recommended — nothing to run locally).
- Two npm scripts: `npm run start:dev` (Nest API) and `npm run start:worker` (BullMQ worker). They share the same source but launch with different entry env (`api` vs `worker`).
- Outgoing email in dev → Ethereal or Mailtrap sandbox account.

### 12.2 CI/CD (GitHub Actions)

- `ci.yml`: install → lint → typecheck → unit → integration (CI runner spins up Mongo & Redis service containers — CI-only, not part of the project) → build → upload coverage.
- `deploy.yml`: on tag `v*` → Render deploy hook (`curl -X POST $RENDER_DEPLOY_HOOK_URL`) for Render, or `eb deploy` for AWS Elastic Beanstalk. No image build/push step.

### 12.3 Environments & config

- `.env.example` checked in; values per env via Render dashboard or AWS Parameter Store / Secrets Manager.
- Validate with **Joi schema** at boot — boot fails on missing/invalid env.

### 12.4 Logging & monitoring

- `nestjs-pino` with request-id, user-id, latency.
- **Sentry** for errors.
- **OpenTelemetry** → Tempo/Datadog (HTTP + Mongo + Redis spans).
- Metrics via `prom-client` → Prometheus → Grafana (RED metrics + queue depth).

### 12.5 Health checks

`@nestjs/terminus` — Mongo ping, Redis ping, disk, memory.

### 12.6 Deployment target

- **Render** (MVP) — one **Web Service** (Node runtime, build cmd `npm ci && npm run build`, start cmd `node dist/main.js`) + a separate **Background Worker** service (same repo, start cmd `node dist/worker.js`). Managed Mongo (or MongoDB Atlas) + Redis (or Upstash) attached via env vars. Autoscaling enabled per service.
- **AWS** (scale) — **Elastic Beanstalk** Node platform for the API + a second EB env (or **Lambda + SQS**) for workers. Pair with **MongoDB Atlas**, **ElastiCache** for Redis, **S3** for uploads, **CloudWatch** for logs/metrics.

---

## 13. Testing Strategy

| Level | Scope | Tools |
|---|---|---|
| Unit | services, guards, mappers — domain logic | Jest, ts-mockito |
| Integration | controller↔service↔real Mongo (mongodb-memory-server) and Redis (ioredis-mock) | Jest |
| E2E | full HTTP via `supertest` against ephemeral DB | Jest |
| Contract | Swagger schema snapshot, Pact (mobile↔backend) | Pact |
| Load | k6 scripts for `/auth/login`, `/pomodoro/start`, `/analytics/summary` | k6 |

Coverage target: **≥ 80%** lines on services, **≥ 90%** on guards/auth.

**Mocking strategy:** external boundaries only (FCM, OpenAI, Stripe). Internal modules use real implementations via the test module to catch wiring bugs.

---

## 14. Swagger Documentation & API Testing Plan

**Swagger UI is the primary API testing surface** for this project (no Postman required). Every endpoint must be fully exercisable from `/docs` with "Try it out".

### 14.1 Setup

```ts
const config = new DocumentBuilder()
  .setTitle('Focaly API')
  .setDescription('Study Management Mobile App backend')
  .setVersion('1.0')
  .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'access-token')
  .addSecurityRequirements('access-token')
  .addTag('Auth')
  .addTag('Users')
  .addTag('Subjects')
  // ... one tag per module
  .build();

const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('docs', app, document, {
  swaggerOptions: {
    persistAuthorization: true,        // keeps Bearer token across page reloads
    displayRequestDuration: true,
    filter: true,
    tryItOutEnabled: true,
    docExpansion: 'none',
  },
});
```

### 14.2 Making every endpoint testable from Swagger UI

- **Bearer auth button** — paste the access token once, "Authorize" → all protected endpoints become callable. `persistAuthorization: true` survives reload.
- **Rich DTO docs** — every DTO field uses `@ApiProperty({ example, description, required, enum, minimum, maximum })` so the "Try it out" form pre-fills realistic values.
- **Response examples** — every controller method declares `@ApiResponse({ status, type, example })` for both success and error shapes so users see what to expect before sending.
- **Error envelope** — global exception filter returns a single shape (`{ code, message, details? }`); documented once as a `@ApiExtraModels(ErrorResponse)` schema referenced from all error responses.
- **File uploads** — `@ApiConsumes('multipart/form-data')` + `@ApiBody({ schema: { type:'object', properties:{ file:{ type:'string', format:'binary' } } } })` so avatar/lecture image uploads work directly in Swagger UI.
- **Query helpers** — `@ApiQuery` with `example` and `enum` for all filter/sort/pagination params.
- **Path params** — `@ApiParam` with example ObjectIds.

### 14.3 Grouping & versioning

- **Grouping** by `@ApiTags('Auth' | 'Subjects' | ...)` — one tag per module, matching the 16 modules in §3.
- **Versioning** via URI: `app.enableVersioning({ type: VersioningType.URI })` → `/v1/...`. New shapes go under `/v2/...`.
- All schemas auto-generated from DTOs decorated with `@ApiProperty`.

### 14.4 Auth flow inside Swagger UI

1. Open `/docs` → expand `Auth` tag.
2. `POST /v1/auth/register` → "Try it out" → send → 201.
3. `POST /v1/auth/login` → "Try it out" → send → copy `tokens.accessToken` from response.
4. Click **Authorize** (top-right) → paste token → "Authorize" → close.
5. Every endpoint is now callable; tokens persist across reloads.
6. For refresh-token flow, a separate `Bearer` scheme (`refresh-token`) is registered so you can paste a refresh token only on `/auth/refresh`.

### 14.5 Environments

- `/docs` enabled in **dev** and **staging**, **disabled in production** by default (gate with `NODE_ENV !== 'production'` OR protect behind basic-auth via `express-basic-auth` middleware for prod).
- Staging Swagger is the QA team's tool; mobile devs hit dev Swagger.

### 14.6 OpenAPI artifact

- Export `openapi.json` in CI (`npm run swagger:export`) and commit to `/docs/openapi.json`.
- Used to (a) generate mobile client types via `openapi-typescript`, (b) lint with Spectral, (c) diff between PRs to flag breaking changes.

### 14.7 Testing checklist per endpoint

For every endpoint a developer adds:
- [ ] `@ApiOperation({ summary, description })`
- [ ] `@ApiResponse` for the success status, with `type` or `schema.example`
- [ ] `@ApiResponse` for each error status the controller can throw (400/401/403/404/409/422/429)
- [ ] DTO fields have `@ApiProperty({ example })`
- [ ] If protected: relies on global Bearer; no extra annotation needed
- [ ] Manually verify "Try it out" succeeds in `/docs` before opening PR — this is part of the PR checklist

---

## 15. Development Roadmap

### Phase 0 — Scaffolding (Week 1)
- This `docs/architecture.md` committed (single source of truth).
- Nest scaffold, config module, Mongo+Redis wiring, Swagger, Pino, Sentry, CI baseline.

### MVP (Weeks 2–5)
- `auth` (email + Google), `users`, `subjects` (with 3-cap), `study-schedules`, `pomodoro`, `streaks`, `tasks/revisions/lectures/exams` via PlannedItem, basic `notifications` (FCM + scheduling), `health`.

### V1 (Weeks 6–8)
- `subscription` (Stripe + IAP), `PremiumGuard`, basic `analytics` (weekly), `uploads` (presigned), audit logs, rate limiting hardening, E2E test suite, deploy to Render.

### V2 (Weeks 9–12)
- `ai` (Notes Assistant, flashcards, questions), full analytics (date-range, heatmap, per-subject), Focus Mode logic, advanced reminders (RRULE), notification preferences UI, leaderboard (friends), admin dashboard.

### V3 (post-launch)
- Multi-region, read replicas, study-group/social features, web companion, push to APNs direct, ML-based study recommendations.

### Priority signals
1. Auth + Subjects + Pomodoro + Streaks (core habit loop) — week 2–3
2. Schedules + Notifications (retention) — week 3–5
3. Subscription (revenue) — week 6–7
4. AI + Analytics (premium upsell) — week 9–11

---

## 16. Bonus

### 16.1 npm packages

`@nestjs/{common,core,config,jwt,passport,mongoose,bullmq,schedule,swagger,terminus,cqrs,throttler}`,
`passport`, `passport-jwt`, `passport-google-oauth20`, `google-auth-library`,
`mongoose`, `class-validator`, `class-transformer`,
`bullmq`, `ioredis`,
`firebase-admin`, `stripe`,
`nestjs-pino`, `pino-pretty`, `@sentry/node`, `@opentelemetry/*`,
`helmet`, `compression`, `cookie-parser`,
`argon2`, `nanoid`, `dayjs`, `rrule`, `zod`,
`@aws-sdk/client-s3`, `@aws-sdk/client-textract`,
`openai`,
dev: `jest`, `@nestjs/testing`, `supertest`, `mongodb-memory-server`, `eslint`, `prettier`, `husky`, `lint-staged`.

### 16.2 NestJS patterns to use

- **Repository abstraction** per module (avoid leaking Mongoose into services).
- **CQRS events** (`@nestjs/cqrs`) for cross-module fan-out.
- **Global filters & interceptors** for consistent error envelope and timing.
- **Custom decorators**: `@CurrentUser()`, `@Public()`, `@Premium()`, `@Idempotent()`.
- **DTO + ViewModel separation** — never return Mongoose docs directly; map to plain objects.
- **Domain events emitted from services, not controllers**.

### 16.3 Common mistakes to avoid

- Returning `_id` (use `id`) and `__v` to clients — strip via interceptor.
- Performing reminder scheduling only in Redis — survives nothing if Redis flushes; always persist to Mongo first.
- Storing FCM tokens on the user doc only — tokens are per-device.
- Doing OpenAI calls in the request lifecycle — always queue.
- One huge `User` document with arrays of subjects/tasks — use real collections.
- Trusting client-side `plan: 'premium'` — always re-derive on the server.
- Forgetting timezone in streak math — store user TZ and compute local-day windows.
- Coupling controllers to Mongoose — slows future swap and tests.

### 16.4 Scalability tips

- Make every API stateless; never use in-memory caches across instances.
- Use Redis as the throttler/cache/queue backend so scaling is just `replicas++`.
- Pre-compute analytics; don't aggregate raw collections in user-facing requests.
- Shard logically by `userId` if a single collection ever crosses ~100M docs (Mongo sharding key = `{ userId: 'hashed' }`).
- Keep workers separate from web — independent scaling and blast-radius isolation.

### 16.5 Naming conventions

| Item | Convention | Example |
|---|---|---|
| Files | kebab-case | `study-schedules.controller.ts` |
| Classes | PascalCase | `StudySchedulesController` |
| Variables/methods | camelCase | `getUpcomingReminders` |
| DTO suffix | `Dto` | `CreateSubjectDto` |
| Events | PastTense + `Event` | `PomodoroCompletedEvent` |
| Mongoose schemas | singular | `Subject`, `User` |
| Collections | plural snake | `study_schedules` |
| Env vars | UPPER_SNAKE | `JWT_PRIVATE_KEY` |
| API routes | plural kebab | `/study-schedules` |

### 16.6 Coding standards

- Strict TS (`strict: true`, `noUncheckedIndexedAccess: true`).
- ESLint `@typescript-eslint/recommended-type-checked` + `eslint-plugin-import` order.
- Prettier with 100-col, single quotes.
- Husky pre-commit: `lint-staged` runs eslint --fix + prettier; pre-push runs `npm test`.
- Conventional Commits + Commitlint.
- ADRs for any non-trivial decision (`docs/adr/0001-modular-monolith.md`).

---

## Verification (how to test end-to-end after implementation)

**All manual API testing is done from Swagger UI at `/docs` — no Postman needed.**

1. **Local stack**: ensure local Mongo + Redis are running (or point env at Atlas + Upstash). `npm run start:dev` runs the API; `npm run start:worker` runs the BullMQ worker.
2. **Open Swagger**: navigate to `http://localhost:3000/docs` — confirm all 16 module tags appear, the **Authorize** button is present, and `persistAuthorization` keeps the token across refreshes.
3. **Auth flow (in Swagger)**:
   - `POST /v1/auth/register` → 201
   - Verify email via Mailtrap/Ethereal inbox
   - `POST /v1/auth/login` → copy `accessToken` and `refreshToken` from the response panel
   - Click **Authorize** (top-right) → paste access token → "Authorize"
   - `GET /v1/users/me` → 200 with profile
   - `POST /v1/auth/refresh` (paste refresh token) → new pair
   - `POST /v1/auth/logout` → 204
4. **Free-plan guard (in Swagger)**: as a free user, `POST /v1/subjects` three times → 201 each; the 4th → 403 with `code: SUBJECT_LIMIT_REACHED`. The error envelope renders directly under "Try it out".
5. **Notification scheduling (in Swagger)**: `POST /v1/subjects/:id/schedules` with `startAt = now + 16min, reminderMinutesBefore: 15` → confirm a `notification_jobs` row exists with `scheduledAt = startAt - 15m` → within ~1 min a BullMQ delayed job is scheduled (visible in Bull-board) → at fire time FCM is called and `GET /v1/notifications` shows the new inbox row.
6. **Pomodoro → streak → analytics (in Swagger)**: `POST /v1/pomodoro/start` → `POST /v1/pomodoro/:id/complete` with `cycles: 3` → `GET /v1/streaks/me` shows `current` incremented → `GET /v1/analytics/summary?from=&to=` reflects the minutes (premium account).
7. **Premium gate (in Swagger)**: as a free user, `GET /v1/analytics/summary` → 403 `PREMIUM_REQUIRED`. Trigger Stripe test webhook (`stripe trigger checkout.session.completed`) → re-call same endpoint → 200.
8. **AI flow (in Swagger, premium)**: `POST /v1/uploads/presign` → upload image to returned URL → `POST /v1/ai/notes/jobs` returns `jobId` → poll `GET /v1/ai/notes/jobs/:id` from Swagger until `status: completed` → artifacts contain summary + flashcards + questions matching the documented JSON schemas.
9. **Multipart upload via Swagger**: `POST /v1/users/me/avatar` with the file picker that Swagger renders thanks to `@ApiConsumes('multipart/form-data')` → 200 with updated avatar URL.
10. **Error shapes**: deliberately submit invalid bodies (missing required fields, wrong enum) → Swagger shows the documented 400/422 envelope, matching the response example.
11. **Tests**: `npm run test` (unit) and `npm run test:e2e` both green; coverage ≥ 80% lines.
12. **Health**: `GET /health/ready` returns 200 with `{ db: up, redis: up, fcm: up }`.
13. **OpenAPI lint**: `npm run swagger:export && npx @stoplight/spectral-cli lint docs/openapi.json` passes with zero errors — guarantees every endpoint is properly documented.
14. **Load smoke**: `k6 run scripts/k6/login.js` at 50 RPS sustains p95 < 200 ms locally.
15. **Production deploy**: tag `v0.1.0` → CI triggers Render deploy hook → web + worker services build and start → `/health` green; manually run steps 3–10 against the live URL using **production Swagger** (protected by basic-auth as described in §14.5).
