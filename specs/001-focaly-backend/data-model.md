# Phase 1 Data Model: Focaly Backend

**Feature**: 001-focaly-backend
**Source**: spec.md §Key Entities, `docs/architecture.md` §2, research.md (RD-1 through RD-4).

This document is normative for the data shape; `docs/architecture.md` §2 stays current for index strategy and example documents and is referenced inline.

---

## Entities

### User

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | Surfaced to clients as `id` (strip `_id`/`__v` in TransformInterceptor). |
| `email` | string | required, lowercase, unique | Canonical identity across email and Google sign-in (FR-001). |
| `passwordHash` | string? | nullable | Null when Google-only. argon2id with memoryCost 64 MB. |
| `googleId` | string? | sparse, unique-when-present | Set on first Google sign-in. |
| `name` | string | required | Display name. |
| `avatarUrl` | string? | | S3 URL from `uploads` module. |
| `emailVerified` | boolean | default `false` | Drives the soft-gate (RD-1): blocks change-password, change-email, subscription-purchase only. |
| `role` | enum `'user' \| 'admin'` | default `'user'` | `admin` is out of MVP scope; reserved. |
| `plan` | enum `'free' \| 'premium'` | default `'free'` | Mirror from `Subscription`; never trust client (FR-035). |
| `premiumUntil` | Date? | | Mirror; `PremiumGuard` checks both `plan` and `premiumUntil > now`. |
| `settings` | object | required | See below. |
| `totalPoints` | number | default 0 | Mirror of streak + planned-item rewards. |
| `lastActiveAt` | Date? | | Touched on every authenticated request via interceptor (sampled). |
| `isDeleted` | boolean | default `false`, indexed | Soft-delete flag (FR-009). |
| `deletedAt` | Date? | | Set on soft-delete; 30-day purge worker keys off this (SC-012). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**`User.settings` shape**:

```ts
{
  locale: string,                 // BCP-47, e.g. "en-US"
  timezone: string,               // IANA, e.g. "Europe/Berlin" — used by streak math (FR-020)
  focusMode: boolean,             // global Focus Mode toggle (FR-030)
  notifications: {
    reminders: boolean,           // user-toggleable (FR-029)
    streak: boolean,              // user-toggleable
    marketing: boolean,           // user-toggleable
    // reward + system are always-on (not user-toggleable); Focus Mode still suppresses them (FR-030)
  }
}
```

**Indexes** (`docs/architecture.md` §2.4): `email` unique; `googleId` sparse; `isDeleted` plain; `deletedAt` plain (for the purge worker).

---

### AuthSession

One row per signed-in device (FR-003).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | indexed | |
| `deviceId` | string | required | Client-supplied stable device identifier. |
| `refreshTokenHash` | string | required | argon2id hash of the refresh credential (FR-005). |
| `userAgent` | string? | | For the active-devices list. |
| `ip` | string? | | First-seen IP. |
| `fcmToken` | string? | | Per-device push token (FR-003, FR-031). |
| `expiresAt` | Date | required, TTL index | TTL drops expired sessions automatically. |
| `revokedAt` | Date? | | Set on individual or bulk revoke (FR-004). |
| `family` | string | required | Refresh-rotation family id; reuse-on-different-jti within a family → revoke the family (FR-007). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, deviceId)` unique; `expiresAt` TTL (`expireAfterSeconds: 0`).

---

### Subject

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | Ownership (FR-046). |
| `name` | string | required, trim | Text-indexed for search. |
| `color` | string? | | UI hint. |
| `icon` | string? | | UI hint. |
| `dailyTargetMinutes` | number | default 0 | Per-day study goal. |
| `progressPercent` | number | default 0, 0–100 | Recomputed on `chapter.completed`. |
| `isArchived` | boolean | default `false`, indexed | Free-plan cap counts non-archived only (FR-012). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, isArchived)`; text on `name`.

**Free-plan rule (FR-012)**: before insert OR before un-archive, count `userId == current && isArchived == false`; reject if `user.plan == 'free' && count >= 3` with `{ code: 'SUBJECT_LIMIT_REACHED' }`.

---

### Chapter

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `subjectId` | ObjectId(Subject) | required, indexed | |
| `userId` | ObjectId(User) | required, indexed | Denormalized for ownership filter without a join. |
| `title` | string | required | |
| `order` | number | default 0 | Display order. |
| `completed` | boolean | default `false` | Toggling emits `chapter.completed` / `chapter.uncompleted`. |
| `completedAt` | Date? | | |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(subjectId, order)`; text on `title`.

**Cascade**: deleting a Subject deletes its Chapters AND its AI artifacts (RD-4 secondary rule).

---

### StudySchedule

Recurring weekly intent to study a subject (FR-014).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `subjectId` | ObjectId(Subject) | required, indexed | |
| `title` | string | required | |
| `startAt` | Date | required, indexed | First occurrence. |
| `endAt` | Date? | | Optional end date. |
| `daysOfWeek` | number[] | each 0..6 | 0 = Sunday. |
| `rrule` | string? | RFC 5545 | Optional advanced recurrence. |
| `reminderMinutesBefore` | number | default 15 | |
| `reminderEnabled` | boolean | default `true` | |
| `isActive` | boolean | default `true` | |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, startAt)`; `subjectId`.

**Reminder lifecycle**: on create/update, emit `ScheduleChangedEvent`; notifications module computes and writes `NotificationJob` rows for the next 14-day window (FR-027 cancels prior pending rows for this schedule).

---

### PomodoroSession

Single focus session (FR-016/17/18).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `subjectId` | ObjectId(Subject)? | indexed | Optional. |
| `startedAt` | Date | required, indexed | |
| `endedAt` | Date? | | |
| `focusMinutes` | number | default 25 | Configured per session. |
| `breakMinutes` | number | default 5 | |
| `completedCycles` | number | default 0 | Increments on `complete`. |
| `totalFocusMinutes` | number | default 0 | Set on `complete` or `abort`. |
| `status` | enum | required | `'active' \| 'paused' \| 'completed' \| 'aborted'`. |
| `lastTickAt` | Date | required | Updated on every state transition; orphan-abort worker keys off this (RD-2). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, startedAt)` desc; `(status, lastTickAt)` for the orphan-abort sweep.

**State machine**: `active → paused → active → completed | aborted`. Auto-abort (RD-2) on `status == 'active' && now - lastTickAt > 4h`; the worker sets `status = 'aborted'`, `endedAt = lastTickAt + 4h`, `totalFocusMinutes = min(actualElapsed, 4h × focusMinutes/(focusMinutes+breakMinutes))`.

**Streak qualification (RD-3)**: a session counts for streaks iff `status == 'completed' && completedCycles ≥ 1 && focusMinutes ≥ 10`. Enforced in the `PomodoroCompletedEvent` consumer in `streaks`.

---

### Streak

One per user (FR-019/20/21).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | unique | One row per user. |
| `current` | number | default 0 | |
| `longest` | number | default 0 | |
| `lastActiveDate` | string? | `YYYY-MM-DD` | Computed in the user's timezone (FR-020). |
| `points` | number | default 0 | |
| `rewards` | array of `{ code: string; awardedAt: Date }` | | Unlocked badges (`STREAK_3`, `STREAK_7`, `STREAK_30`, `STREAK_100`). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `userId` unique.

**Maintenance**: daily cron `0 3 * * *` UTC scans by timezone bucket; for any user whose `lastActiveDate` is more than 1 calendar day before "today in their tz," set `current = 0`.

---

### PlannedItem (discriminator: task | revision | lecture | exam)

Single collection backs all four user-facing categories (FR-022/23/24).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `subjectId` | ObjectId(Subject)? | indexed | Optional. |
| `kind` | enum | required, indexed | `'task' \| 'revision' \| 'lecture' \| 'exam'`. |
| `title` | string | required | |
| `notes` | string? | | |
| `plannedAt` | Date | required, indexed | |
| `durationMinutes` | number? | | |
| `recurrence` | enum? | | `'daily' \| 'weekly' \| 'once'`. |
| `reminderMinutesBefore` | number | default 15 | |
| `reminderEnabled` | boolean | default `true` | |
| `completed` | boolean | default `false` | |
| `completedAt` | Date? | | |
| `rewardPoints` | number | default 0 | Configurable per `kind`. |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, plannedAt)`; `(userId, kind, plannedAt)`; `(userId, completed)`.

**Streak rule (RD-3)**: completion of a PlannedItem awards `rewardPoints` only; it does NOT advance the streak under any circumstance.

---

### Notification (Inbox Entry)

User-visible inbox row (FR-028).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `type` | enum | required | `'reminder' \| 'streak' \| 'reward' \| 'system'`. |
| `title` | string | required | |
| `body` | string | | |
| `data` | object | | Structured payload for deep-linking. |
| `read` | boolean | default `false` | |
| `expiresAt` | Date | default `now + 90d`, TTL index | Auto-purge (FR-028). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, createdAt desc)`; `expiresAt` TTL.

---

### NotificationJob

Scheduling table — source of truth for pending pushes (FR-025/26/27).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `refType` | enum | required | `'study_schedule' \| 'planned_item' \| 'system'`. |
| `refId` | ObjectId | required | The owning entity. |
| `category` | enum | required | `'reminder' \| 'streak' \| 'reward' \| 'system'` — gates preference + Focus Mode check at dispatch (FR-029/30). |
| `scheduledAt` | Date | required, indexed | When to fire. |
| `status` | enum | default `'pending'`, indexed | `'pending' \| 'queued' \| 'sent' \| 'failed' \| 'cancelled'`. |
| `attempts` | number | default 0 | |
| `lastError` | string? | | |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(scheduledAt, status)`; `(refType, refId)` for cancellation lookups.

**Cancellation (FR-027)**: deleting / disabling-reminders / changing schedule on the underlying ref sets all matching `(refType, refId, status='pending')` rows to `status='cancelled'`.

---

### Subscription

Single source of truth for plan state (FR-032/33/34, AR-10).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | unique | One paid subscription per user. |
| `provider` | enum | required | `'stripe' \| 'google_play' \| 'app_store'`. |
| `providerSubId` | string | required | Provider's subscription identifier. |
| `status` | enum | required | `'trialing' \| 'active' \| 'past_due' \| 'canceled' \| 'expired'`. |
| `currentPeriodEnd` | Date | | |
| `priceId` | string | | |
| `lastEventAt` | Date | | Highest provider event timestamp seen; out-of-order events older than this are ignored (spec edge case). |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `userId` unique; `(provider, providerSubId)` unique.

**Mirror sync**: on every status transition, update `User.plan` and `User.premiumUntil` in the same transaction-equivalent unit (single doc write per side, ordering preserved).

---

### PaymentEvent

Webhook audit + idempotency (FR-034).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `provider` | enum | required | `'stripe' \| 'google_play' \| 'app_store'`. |
| `eventId` | string | required | Provider event identifier. |
| `userId` | ObjectId(User)? | | Resolved at processing time. |
| `payload` | object | required | Raw event payload. |
| `processedAt` | Date? | | |
| `outcome` | enum? | | `'applied' \| 'noop' \| 'error'`. |
| `error` | string? | | |
| `createdAt` | Date | `timestamps: { createdAt: true, updatedAt: false }` | |

**Indexes**: `(provider, eventId)` unique → enforces idempotency at insert time; duplicate inserts return the existing row (no-op).

---

### AiJob

User-submitted async AI request (FR-036/37/38/39/40).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `subjectId` | ObjectId(Subject)? | indexed | Optional but typical. |
| `imageKeys` | string[] | required, non-empty | S3 keys returned by the upload presign flow. |
| `status` | enum | required, indexed | `'queued' \| 'processing' \| 'completed' \| 'failed'`. |
| `failureReason` | string? | | User-readable when `status = 'failed'` (FR-040). |
| `ocrCacheHash` | string? | | sha256 of input image set; for reuse (AR-8). |
| `tokensIn` | number? | | Cost tracking. |
| `tokensOut` | number? | | |
| `startedAt` | Date? | | |
| `completedAt` | Date? | | |
| `createdAt`/`updatedAt` | Date | `timestamps: true` | |

**Indexes**: `(userId, status)`; `(userId, createdAt desc)` for "my recent jobs."

**Rate limit (FR-039)**: a Redis sliding window keyed on `ai:user:{userId}:hour` (capacity 5, window 1h) and a monthly counter on `ai:user:{userId}:month:{YYYYMM}` (capacity 30, expires at next month start). Reject `429` with both window resets in `Retry-After` semantics.

---

### AiArtifact

Produced AI result (FR-037). Retained for account lifetime (RD-4).

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User) | required, indexed | |
| `subjectId` | ObjectId(Subject) | required, indexed | Required (used for cascade delete). |
| `jobId` | ObjectId(AiJob) | required, indexed | Originating job. |
| `kind` | enum | required | `'summary' \| 'flashcards' \| 'questions'`. |
| `content` | object | required | Shape per `kind` — see below. |
| `createdAt` | Date | `timestamps: { createdAt: true, updatedAt: false }` | |

**Content shapes** (validated with Zod at write — FR-040):

```ts
// summary
{ text: string }

// flashcards
{ cards: Array<{ front: string; back: string; tag?: string }> }

// questions
{ questions: Array<{ q: string; difficulty: 'easy' | 'medium' | 'hard'; topic?: string }> }
```

**Cascade**: deleting the Subject deletes its AiArtifacts; soft-deleting the User defers deletion to the 30-day purge worker (SC-012).

---

### AuditLog

Security-relevant event log (FR-049). 1-year TTL.

| Field | Type | Constraints | Notes |
|---|---|---|---|
| `_id` | ObjectId | PK | |
| `userId` | ObjectId(User)? | indexed | Null for system-initiated events. |
| `actor` | enum | required | `'user' \| 'admin' \| 'system' \| 'webhook'`. |
| `eventType` | string | required, indexed | e.g. `auth.login`, `auth.refresh.reuse`, `plan.upgrade`, `account.softDelete`. |
| `requestId` | string? | | For correlation with logs. |
| `ip` | string? | | |
| `userAgent` | string? | | |
| `data` | object? | | Event-specific payload. |
| `createdAt` | Date | `timestamps: { createdAt: true, updatedAt: false }`, TTL `expireAfterSeconds: 31536000` | |

**Indexes**: `(userId, createdAt desc)`; `(eventType, createdAt desc)`; `createdAt` TTL (1 year).

---

## Relationships (ERD summary)

```
User 1───* AuthSession                       (one per signed-in device)
User 1───* Subject 1───* Chapter
User 1───* StudySchedule *───1 Subject
User 1───* PlannedItem  *───1 Subject        (task | revision | lecture | exam)
User 1───1 Streak
User 1───* PomodoroSession *───1 Subject
User 1───* Notification
User 1───* NotificationJob
User 1───1 Subscription
User 1───* PaymentEvent (denormalized)
User 1───* AiJob 1───* AiArtifact *───1 Subject
User 1───* AuditLog
```

## Cascade & retention summary

| When | What happens |
|---|---|
| Subject deleted (hard delete; the API only soft-archives — see FR-011) | Chapters of that Subject deleted; AiArtifacts referencing that Subject deleted. PlannedItems and Pomodoro/Schedule rows referencing the Subject have their `subjectId` set to `null` (history preserved). |
| User soft-deleted (`isDeleted = true, deletedAt = now`) | All sign-in attempts blocked; user data remains for 30 days; purge worker hard-deletes everything user-scoped (User, AuthSession, Subject, Chapter, StudySchedule, PomodoroSession, Streak, PlannedItem, Notification, NotificationJob, Subscription, PaymentEvent, AiJob, AiArtifact). AuditLog retained 1 year regardless. |
| AuthSession `expiresAt` reached | TTL drops the row; refresh impossible. |
| Notification `expiresAt` reached (90d) | TTL drops the row. |
| AuditLog 1y old | TTL drops the row. |
| Pomodoro session orphaned >4h (RD-2) | Auto-aborted by maintenance cron; truncated `totalFocusMinutes`. |
