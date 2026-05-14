# Quickstart: Focaly Backend

**Feature**: 001-focaly-backend
**Reads**: `spec.md` (what to build), `data-model.md` (entities), `contracts/openapi.yaml` (the API contract), `research.md` (Phase-0 decisions).

This is the minimum viable run-and-verify script. It assumes `focaly-backend/` will be created by `/speckit.tasks` and `/speckit.implement`; nothing in this section creates the source tree.

---

## 1. Prerequisites

- **Node.js 20 LTS** (matches Render's Node runtime).
- **A MongoDB instance** — either local install or MongoDB Atlas free tier (recommended; less to run locally).
- **A Redis instance** — either local install or Upstash Redis free tier (recommended).
- **An S3 bucket** (or local MinIO for dev) for avatar/lecture-image uploads.
- A Firebase project with FCM enabled (needed only to actually send pushes — see §6 for a mock path that lets you defer this).
- Stripe + Google Cloud + Apple Developer accounts (only needed for the billing endpoints — `/auth`, `/subjects`, `/pomodoro` work without them).

## 2. Local-dev env

The full set of env vars is governed by `src/config/validation.schema.ts` (a Joi schema); boot fails if any required var is missing. The MVP-essential minimum:

```bash
NODE_ENV=development
PORT=3000

# DB / cache
MONGO_URI=mongodb://localhost:27017/focaly
REDIS_URL=redis://localhost:6379

# JWT (RS256 — generate a 2048-bit pair once; keep the private key off git)
JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
JWT_ACCESS_TTL=900            # 15 min — FR-005
JWT_REFRESH_TTL=2592000       # 30 d  — FR-005

# Auth (optional in dev)
GOOGLE_CLIENT_ID=...

# Email (use Mailtrap/Ethereal sandbox in dev)
MAIL_PROVIDER=ethereal
MAIL_FROM="Focaly <noreply@focaly.app>"

# S3 (or MinIO)
S3_BUCKET=focaly-dev
S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_ENDPOINT=http://localhost:9000   # only when pointing at MinIO

# Optional in dev (mock these — see §6)
FCM_SERVICE_ACCOUNT_JSON=
OPENAI_API_KEY=
AWS_TEXTRACT_REGION=us-east-1
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

## 3. Run the API + the worker

Two npm scripts, same source tree:

```bash
npm ci
npm run start:dev      # → http://localhost:3000 — Swagger UI at /docs
# in a second terminal:
npm run start:worker   # consumes BullMQ queues + runs the cron schedule
```

Boot logs should report `db: up, redis: up` from `GET /v1/health/ready`.

## 4. Open Swagger and verify the 9 user stories

Navigate to `http://localhost:3000/docs`. Confirm:

- 16 tagged groups visible.
- `Authorize` button present in the top right.
- `persistAuthorization: true` (token survives reload).

### Story 1 — Auth (US1)

1. `POST /v1/auth/register` with `{ email, password, name }` → `201` with `tokens.accessToken`.
2. Click **Authorize** → paste the access token → close.
3. `POST /v1/auth/verify-email` with the token from the Ethereal/Mailtrap inbox → `204`.
4. `GET /v1/users/me` → `200` with profile.
5. `GET /v1/auth/sessions` → exactly one session, `current: true`.
6. `POST /v1/auth/refresh` (paste refresh token in the `bearerRefresh` slot) → new token pair; the old refresh is rejected on a second attempt (FR-007).
7. `POST /v1/auth/logout` → `204`.

### Story 2 — Subjects + free-plan cap (US2)

After re-login:

1. `POST /v1/subjects` three times with different names → all `201`.
2. `POST /v1/subjects` a fourth time → `403` with `{ code: SUBJECT_LIMIT_REACHED }`.
3. `DELETE /v1/subjects/{id1}` → archives → `204`.
4. `POST /v1/subjects` again → now `201`.
5. `POST /v1/subjects/{id}/chapters` ×2; `PATCH /v1/subjects/{id}/chapters/{chId}` with `completed: true`; `GET /v1/subjects/{id}/progress` → `progressPercent = 50`.

### Story 3 — Schedules + pomodoro (US3)

1. `POST /v1/subjects/{id}/schedules` with `startAt = now + 16 min`, `reminderMinutesBefore: 15` → `201`. A `notification_jobs` row appears with `scheduledAt = startAt - 15min`.
2. `POST /v1/pomodoro/start` with `{ subjectId, focusMinutes: 25 }` → `201` (`status: active`).
3. `POST /v1/pomodoro/{id}/pause`; `POST /v1/pomodoro/{id}/resume`.
4. `POST /v1/pomodoro/{id}/complete` with `{ cycles: 3 }` → `status: completed`, `totalFocusMinutes: 75`.
5. `GET /v1/pomodoro/today` → `totalFocusMinutes: 75`.
6. `GET /v1/pomodoro/history?from=&to=` → paginated history.

### Story 4 — Streaks (US4)

1. After step (Story 3 step 4) which qualifies (FR-020 + RD-3: `status = completed && completedCycles ≥ 1 && focusMinutes ≥ 10`), `GET /v1/streaks/me` → `current: 1`.
2. Sanity: try starting a 5-minute focus session (`focusMinutes: 5`) and completing it. Streak does NOT advance (RD-3).
3. To verify the milestone path without waiting 3 days, run the seed helper `npm run seed:streak -- --user=<userId> --days=2` (writes the prior two `lastActiveDate` values), then complete a qualifying pomodoro → `STREAK_3` reward appears in `rewards[]` and a notification arrives.

### Story 5 — Planned items + reminders (US5)

1. `POST /v1/exams` with `plannedAt = now + 90 min`, `reminderMinutesBefore: 60`, `subjectId: <id>` → `201`.
2. Wait until the scheduled fire (`now + 30 min`). The BullMQ delayed job fires, FCM is called, and `GET /v1/notifications` shows the new inbox entry.
3. `POST /v1/exams/{id}/complete` → `200`. Reward points are added; **streak is NOT advanced** (RD-3 / FR-024). `GET /v1/streaks/me.current` is unchanged.
4. `PATCH /v1/exams/{id}` with a new `plannedAt` → the prior `notification_jobs` row is cancelled and a new one written (FR-027).

### Story 6 — Notifications + Focus Mode (US6)

1. `PATCH /v1/users/me/settings` with `notifications.reminders: false` → subsequent reminders create an inbox row but NO push fires.
2. Re-enable reminders. `PATCH /v1/users/me/settings` with `focusMode: true`.
3. Start a pomodoro and, while it's `active`, fire a reminder. The push is suppressed (FR-030 + Q4 clarification); the inbox row is still written.
4. Complete the pomodoro → on the next event, push delivery resumes.

### Story 7 — Premium gate (US7)

1. As a free user, `GET /v1/analytics/summary?from=2026-01-01&to=2026-05-01` → `403 PREMIUM_REQUIRED`.
2. Trigger Stripe in test mode: `stripe trigger checkout.session.completed --add data.object.metadata.userId=<userId>` → webhook hits `/v1/subscription/webhook/stripe`; `User.plan` flips to `premium` within seconds.
3. Repeat the analytics call → `200`.
4. Trigger `customer.subscription.deleted` → `User.plan` flips back to `free`; the call goes back to `403`.
5. Re-deliver the same webhook event → no double-grant (FR-034: unique `(provider, eventId)`).

### Story 8 — AI notes (US8, premium)

1. As premium: `POST /v1/uploads/presign` with `{ kind: 'lecture-image', mimeType: 'image/jpeg', sizeBytes: 1024000 }` → presigned URL + key.
2. PUT the image to the URL (Swagger UI cannot PUT to S3 directly — use a one-line `curl --upload-file`).
3. `POST /v1/ai/notes/jobs` with `{ subjectId, imageKeys: [<key>] }` → `202` with `jobId`.
4. Poll `GET /v1/ai/notes/jobs/{jobId}` → eventually `status: completed`; `GET /v1/ai/artifacts?subjectId=<id>` returns summary + flashcards + questions.
5. Rate-limit smoke: fire six submissions back-to-back. The sixth returns `429 AI_RATE_LIMIT` with a `Retry-After` header (FR-039: 5/hour).

### Story 9 — Analytics (US9, premium)

1. `GET /v1/analytics/summary?from=&to=` (a date range that includes the pomodoro from Story 3) → totals match Story 3.4's `totalFocusMinutes`.
2. `GET /v1/analytics/by-subject?from=&to=` → breakdown that sums to the same total (FR-043).
3. `GET /v1/analytics/heatmap?year=2026` → one entry per day with the focus minutes for that day.

## 5. Tests

```bash
npm run test            # unit + integration (mongodb-memory-server, ioredis-mock)
npm run test:e2e        # full HTTP via supertest
npm run swagger:export  # writes docs/openapi.json
npx @stoplight/spectral-cli lint focaly-backend/docs/openapi.json
k6 run scripts/k6/login.js        # 50 RPS → p95 < 200 ms locally
```

Coverage targets: ≥ 80% on services, ≥ 90% on guards/auth.

## 6. Mocking the external providers in dev

- **FCM**: set `FCM_SERVICE_ACCOUNT_JSON=` (empty) — the infrastructure layer detects this and substitutes a stdout-logging fake. Pushes are not delivered to a phone; the inbox is still written, which is enough to verify scheduling logic.
- **OpenAI + Textract**: set `OPENAI_API_KEY=` (empty) — the AI worker substitutes deterministic fixture artifacts (real summary/flashcards/questions shapes, lorem-ipsum content). Lets you exercise the job lifecycle without spending tokens.
- **Stripe**: use the Stripe CLI's `stripe listen --forward-to localhost:3000/v1/subscription/webhook/stripe`. Test cards work end-to-end; no real charges.

## 7. Verifying the non-functional success criteria locally

| SC | Local check |
|---|---|
| SC-002 (perceived < 1s) | `k6 run scripts/k6/read-paths.js` at 50 RPS → p95 < 1000 ms on `/users/me`, `/subjects`, `/pomodoro/today`, `/notifications`. |
| SC-003 (99% reminders in 60s of fire time) | Create 50 schedules with random offsets in the next 30 minutes; verify `notification_jobs.sentAt - scheduledAt ≤ 60s` for ≥ 49 of 50. |
| SC-004 (plan transition in 60s) | Time from `stripe trigger` to `User.plan` reflecting the change. |
| SC-006 (plan enforcement correct 100%) | An automated suite that loops every premium-only endpoint × {free user, premium user}. |
| SC-007 (streak timezone correctness) | Set user's `settings.timezone` to `Asia/Tokyo`; complete a qualifying pomodoro at 00:30 UTC (09:30 Tokyo local); confirm `lastActiveDate` is the Tokyo calendar day, not the UTC one. |
| SC-008 (idempotent webhooks) | Re-deliver the same Stripe event twice; second delivery is a no-op (visible in `payment_events.outcome = 'noop'`). |
| SC-009 (no cross-user leak) | Authenticated as user A, request user B's `/subjects/{idOfB}` → `404` (we return not-found rather than 403 to avoid resource enumeration). |
| SC-011 (every endpoint testable in Swagger) | Manual: walk every tag in `/docs`; every endpoint must have an example and the "Try it out" must succeed for the authenticated scenarios. |
| SC-013 (99.5% monthly availability) | Local can only assert health checks; the actual SLO is measured in staging/prod via the gateway. |

## 8. Production deploy verification

1. Tag the repo `v0.1.0`. CI triggers Render deploy hook for web + worker services. No image build/push step (FR / architecture §12.6).
2. `GET https://api.focaly.app/v1/health/ready` returns `200` with `db: up, redis: up, fcm: up`.
3. Run the §4 walkthrough against staging Swagger (`https://staging-api.focaly.app/docs`, protected by basic auth — architecture §14.5).
4. Smoke `stripe trigger checkout.session.completed` with a test customer mapped to a staging user — confirm plan flip and that `payment_events` records the delivery.

If any step fails, do NOT promote; investigate before tagging `v0.1.1`.
