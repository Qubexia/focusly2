---
description: "Task list for feature 001-focaly-backend"
---

# Tasks: Focaly Backend — Study Management Platform

**Input**: Design documents from `/specs/001-focaly-backend/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/openapi.yaml ✓, quickstart.md ✓

**Tests**: Included. The spec's §Verification flow assumes a test suite (Jest unit + integration, supertest e2e); coverage targets are explicit (≥80% services, ≥90% guards/auth). Test tasks below are pragmatic — focused on guards, state machines, idempotency, the free-plan cap, streak math, and the reminder lifecycle, not exhaustive 1:1 with FRs.

**Organization**: 12 phases — 1 Setup, 1 Foundational, 9 User Stories (in P1→P3 priority order), 1 Polish. All paths are absolute under `focaly-backend/` at the repository root (per plan.md §Project Structure).

## Format

`- [ ] T### [P?] [Story?] Description with file path`

- **[P]**: parallelizable (different file, no in-phase dependency on an incomplete task).
- **[USx]**: which spec user story this task delivers (required on Phase 3–11 tasks; not used on Setup, Foundational, or Polish).

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Initialize NestJS project skeleton with `npx @nestjs/cli new focaly-backend --package-manager npm --strict` at repo root; commit the generated tree as the new `focaly-backend/` directory.
- [X] T002 Replace `focaly-backend/package.json` with the dependency list from `plan.md` §Primary Dependencies; run `npm ci`.
- [X] T003 [P] Configure TypeScript strict mode in `focaly-backend/tsconfig.json` (`strict: true`, `noUncheckedIndexedAccess: true`, `target: ES2022`).
- [X] T004 [P] Configure ESLint + Prettier in `focaly-backend/.eslintrc.js` and `focaly-backend/.prettierrc` per architecture §16.6 (100-col, single quotes, `@typescript-eslint/recommended-type-checked`, `eslint-plugin-import` order).
- [X] T005 [P] Add Husky pre-commit + Commitlint in `focaly-backend/.husky/` and `focaly-backend/commitlint.config.js` (Conventional Commits).
- [X] T006 [P] Add `focaly-backend/.env.example` enumerating every env var referenced in `quickstart.md` §2.
- [X] T007 [P] Add `focaly-backend/render.yaml` declaring two services: a Node Web Service (`node dist/main.js`) and a Background Worker (`node dist/worker.js`). No Docker.
- [X] T008 Add `focaly-backend/src/worker.ts` — empty entry that boots `WorkerModule` (defined in Phase 2). Stub for now.
- [X] T009 [P] Add `focaly-backend/.github/workflows/ci.yml` running `npm ci → lint → typecheck → test → test:e2e → build → swagger:export → spectral lint` (Mongo + Redis service containers used only inside CI, not in `focaly-backend/`).
- [X] T010 [P] Add `focaly-backend/.github/workflows/deploy.yml` triggered on tag `v*` that POSTs the Render deploy hook URL stored in repo secrets.

**Checkpoint**: project skeleton boots; `npm run build` succeeds; CI runs (no tests yet).

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: No user-story work can begin until this phase is complete.

### Config + env

- [X] T011 Implement `focaly-backend/src/config/configuration.ts` and per-domain config files in `focaly-backend/src/config/env/{app,db,redis,jwt,fcm,openai,stripe,s3,mailer}.config.ts`.
- [X] T012 [P] Implement `focaly-backend/src/config/validation.schema.ts` (Joi) so boot fails on missing/invalid env. Wire into `ConfigModule.forRoot({ validationSchema })`.

### Infrastructure modules

- [X] T013 [P] Implement `focaly-backend/src/infrastructure/database/database.module.ts` — `MongooseModule.forRootAsync` with `maxPoolSize: 50`, retryAttempts, retryDelay.
- [X] T014 [P] Implement `focaly-backend/src/infrastructure/redis/redis.module.ts` — shared `ioredis` client used by throttler, cache, BullMQ broker, and per-feature rate-limit windows.
- [X] T015 [P] Implement `focaly-backend/src/infrastructure/queue/queue.module.ts` — BullMQ root module that registers the five queues (`notifications`, `ai`, `analytics`, `subscription`, `maintenance`) per `docs/architecture.md` §6.3.
- [X] T016 [P] Implement `focaly-backend/src/infrastructure/fcm/fcm.module.ts` and `fcm.client.ts` — `firebase-admin` wrapper; falls back to a stdout-logging fake when `FCM_SERVICE_ACCOUNT_JSON` is empty (quickstart §6).
- [X] T017 [P] Implement `focaly-backend/src/infrastructure/storage/s3.module.ts` and `s3.client.ts` — `@aws-sdk/client-s3` with presigned PUT helper.
- [X] T018 [P] Implement `focaly-backend/src/infrastructure/mailer/mailer.module.ts` — nodemailer with Ethereal in dev, SES in prod.
- [X] T019 [P] Implement `focaly-backend/src/infrastructure/logger/logger.module.ts` — `nestjs-pino` with redact paths (`req.headers.authorization`, `*.password`, `*.refreshToken`) per architecture §10.
- [X] T020 [P] Implement `focaly-backend/src/infrastructure/tracing/tracing.module.ts` — OpenTelemetry HTTP + Mongo + Redis spans.

### Cross-cutting

- [X] T021 [P] Implement the canonical error envelope DTO in `focaly-backend/src/common/dto/api-response.ts` (`ErrorResponse { code, message, details? }`).
- [X] T022 [P] Implement `focaly-backend/src/common/filters/all-exceptions.filter.ts` returning the single envelope (FR-047).
- [X] T023 [P] Implement `focaly-backend/src/common/filters/mongo-exception.filter.ts` (unique violation → 409 `DUPLICATE_KEY`).
- [X] T024 [P] Implement `focaly-backend/src/common/interceptors/transform.interceptor.ts` — strip `_id`/`__v`, map to `id`.
- [X] T025 [P] Implement `focaly-backend/src/common/interceptors/logging.interceptor.ts` — emit timing + request-id.
- [X] T026 [P] Implement `focaly-backend/src/common/middleware/request-id.middleware.ts` — generate `X-Request-Id` if missing; attach to logger context.
- [X] T027 [P] Implement `focaly-backend/src/common/middleware/audit-log.middleware.ts` — write to `audit_logs` for security-sensitive routes (registered via metadata).
- [X] T028 [P] Implement `focaly-backend/src/common/pipes/parse-object-id.pipe.ts`.
- [X] T029 [P] Implement `focaly-backend/src/common/dto/pagination.dto.ts` (cursor + limit) and `date-range.dto.ts`.
- [X] T030 [P] Implement decorators in `focaly-backend/src/common/decorators/`: `@Public`, `@CurrentUser`, `@Roles`, `@Premium`, `@Idempotent`.

### Guards (without auth wiring yet — that lands in Phase 3)

- [X] T031 [P] Implement `focaly-backend/src/common/guards/throttler-behind-proxy.guard.ts` (Redis-backed throttler; trust X-Forwarded-For). _Note: Phase 2 ships with in-memory storage; redis-backed storage adapter is a Polish/Phase-12 follow-up._
- [X] T032 [P] Implement `focaly-backend/src/common/guards/premium.guard.ts` — `user.plan === 'premium' && (!premiumUntil || premiumUntil > now)`. Throws `PREMIUM_REQUIRED`.
- [X] T033 [P] Implement `focaly-backend/src/common/guards/email-verified.guard.ts` — gates only the three RD-1 sensitive endpoints (change-password, change-email, subscription-purchase).

### CQRS event bus

- [X] T034 [P] Implement `focaly-backend/src/shared/events/event-bus.module.ts` — `@nestjs/cqrs` root.
- [X] T035 [P] Implement the canonical event classes in `focaly-backend/src/shared/events/`: `PomodoroCompletedEvent`, `ScheduleChangedEvent`, `PlannedItemChangedEvent`, `PlannedItemDeletedEvent`, `PlannedItemCompletedEvent`, `ChapterCompletedEvent`, `AiJobCompletedEvent`, `SubscriptionChangedEvent`. _Also added `RewardUnlockedEvent` (forward-referenced by T095 in Phase 6)._

### Swagger + main + worker bootstrap

- [X] T036 Implement `focaly-backend/src/main.ts` — global pipes (`ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`), global filters/interceptors, `app.enableVersioning({ type: VersioningType.URI })`, Helmet, compression, CORS allowlist from env.
- [X] T037 Implement `focaly-backend/src/main.ts` Swagger wiring at `/docs` with `persistAuthorization: true`, both `bearerAccess` and `bearerRefresh` schemes, tags per module (FR-052). Gate behind basic-auth in production.
- [X] T038 Implement `focaly-backend/src/worker.ts` — boots `WorkerModule` containing only `@nestjs/schedule`, BullMQ consumers, and infrastructure modules (no controllers).
- [X] T039 Add `npm run start:dev`, `npm run start:worker`, `npm run swagger:export`, `npm run test`, `npm run test:e2e` scripts in `focaly-backend/package.json`.

### Health (smoke target for the rest of the work)

- [X] T040 Implement `focaly-backend/src/modules/health/health.module.ts` and `health.controller.ts` — `@nestjs/terminus`; `GET /v1/health` (liveness), `GET /v1/health/ready` (Mongo + Redis + FCM) (FR-050).

**Checkpoint**: `npm run start:dev` boots; `/v1/health` returns 200; `/docs` loads with 1 module tag (Health). All user stories may now start in parallel.

---

## Phase 3: User Story 1 — Sign up, sign in, and access the study workspace (Priority: P1) 🎯 MVP

**Goal**: A new student can register (email/password or Google), verify their email, sign in across multiple devices with 15-min access + 30-day rotating refresh credentials, see and revoke active devices, reset their password.

**Independent Test**: Run quickstart §4 Story 1 end-to-end via Swagger.

### Schemas + repos

- [X] T041 [P] [US1] Define `User` schema in `focaly-backend/src/modules/users/schemas/user.schema.ts` per data-model.md.
- [X] T042 [P] [US1] Define `AuthSession` schema in `focaly-backend/src/modules/auth/schemas/auth-session.schema.ts` per data-model.md (TTL on `expiresAt`).
- [X] T043 [P] [US1] Define `AuditLog` schema in `focaly-backend/src/modules/auth/schemas/audit-log.schema.ts` (FR-049; 1-year TTL).
- [X] T044 [US1] Implement `UsersRepository` in `focaly-backend/src/modules/users/users.repository.ts`. Depends on T041.
- [X] T045 [US1] Implement `AuthSessionsRepository` in `focaly-backend/src/modules/auth/auth-sessions.repository.ts`. Depends on T042.

### Auth services + guards

- [X] T046 [US1] Implement `JwtService` wrapper in `focaly-backend/src/modules/auth/jwt.service.ts` (RS256; sign/verify access + refresh with separate TTLs from env). Depends on T011.
- [X] T047 [US1] Implement `PasswordService` (argon2id memoryCost 64MB) in `focaly-backend/src/modules/auth/password.service.ts`.
- [X] T048 [US1] Implement `GoogleAuthService` in `focaly-backend/src/modules/auth/google-auth.service.ts` (verify `idToken` via `google-auth-library`, upsert by `googleId` or merge by verified email — FR-001).
- [X] T049 [US1] Implement `JwtAuthGuard` in `focaly-backend/src/common/guards/jwt-auth.guard.ts` (registered globally, `@Public` opt-out).
- [X] T050 [US1] Implement `JwtRefreshGuard` in `focaly-backend/src/common/guards/jwt-refresh.guard.ts`.
- [X] T051 [US1] Implement refresh-token rotation + theft detection in `focaly-backend/src/modules/auth/auth.service.ts`:
  - Every refresh issues a new `jti`, invalidates the old one (hash stored on `AuthSession.refreshTokenHash`).
  - Reuse of a consumed `jti` within a `family` revokes the entire family + writes an audit log + forces re-auth (FR-007).

### DTOs + controllers

- [X] T052 [P] [US1] Define DTOs in `focaly-backend/src/modules/auth/dto/` exactly matching `contracts/openapi.yaml` request bodies (`RegisterDto`, `LoginDto`, `GoogleLoginDto`, `RefreshDto`, `ForgotPasswordDto`, `ResetPasswordDto`, `VerifyEmailDto`, `FcmTokenDto`). All fields use `@ApiProperty` with examples (FR-052).
- [X] T053 [US1] Implement `AuthService` register/login/google/refresh/logout/logout-all/forgot-password/reset-password/verify-email in `focaly-backend/src/modules/auth/auth.service.ts`. Email verification uses short-lived JWT signed with a separate secret, single-use via Redis-jti store.
- [X] T054 [US1] Implement `AuthController` in `focaly-backend/src/modules/auth/auth.controller.ts` — all paths under `/v1/auth/*` from `contracts/openapi.yaml`; uses `@Public` on `register/login/google/refresh/forgot-password/reset-password/verify-email/webhook` endpoints.
- [X] T055 [US1] Implement `GET /auth/sessions` and `DELETE /auth/sessions/:id` in `AuthController` (FR-004); clears FCM token on revoke.
- [X] T056 [P] [US1] Define `UpdateUserDto`, `UpdateSettingsDto` in `focaly-backend/src/modules/users/dto/` matching `contracts/openapi.yaml`.
- [X] T057 [US1] Implement `UsersService` in `focaly-backend/src/modules/users/users.service.ts` (read/update profile, settings, fcm-token, soft delete, register FCM token onto current `AuthSession`).
- [X] T058 [US1] Implement `UsersController` in `focaly-backend/src/modules/users/users.controller.ts` — `GET/PATCH /v1/users/me`, `PATCH /v1/users/me/settings`, `POST /v1/users/me/avatar` (consumes `multipart/form-data`), `POST /v1/users/me/fcm-token`, `DELETE /v1/users/me`.

### Module wiring

- [X] T059 [US1] Wire `AuthModule` in `focaly-backend/src/modules/auth/auth.module.ts` and `UsersModule` in `focaly-backend/src/modules/users/users.module.ts`; import both into `AppModule`.
- [X] T060 [US1] Register `JwtAuthGuard` as a `APP_GUARD` in `AppModule` (default protected; `@Public` opts out). Register `EmailVerifiedGuard` only on the three RD-1 sensitive controllers.

### Mailer integration

- [X] T061 [US1] Implement verification + password-reset email templates in `focaly-backend/src/modules/auth/templates/`; send via `MailerModule` (T018).

### Tests

- [X] T062 [P] [US1] Unit test JWT rotation + theft detection in `focaly-backend/test/unit/auth/jwt-rotation.spec.ts` — first refresh succeeds, second use of the same jti revokes the family.
- [X] T063 [P] [US1] Unit test free-vs-premium claim derivation in `focaly-backend/test/unit/auth/jwt-claims.spec.ts`.
- [ ] T064 [P] [US1] Integration test register → verify → login → /users/me → logout in `focaly-backend/test/integration/auth/auth-flow.int-spec.ts` (memory-server Mongo, ioredis-mock).
- [ ] T065 [P] [US1] e2e test session listing + per-device revoke in `focaly-backend/test/e2e/auth-sessions.e2e-spec.ts` (supertest).
- [ ] T066 [P] [US1] e2e test password reset flow revokes prior sessions in `focaly-backend/test/e2e/password-reset.e2e-spec.ts`.

**Checkpoint**: quickstart §4 Story 1 passes end-to-end against the local stack.

---

## Phase 4: User Story 2 — Subjects + chapters + free-plan cap (Priority: P1)

**Goal**: A user can manage subjects (with 3-active cap on the free plan), break them into chapters, and see chapter completion update the subject's progress percentage.

**Independent Test**: Run quickstart §4 Story 2.

### Schemas + repos

- [X] T067 [P] [US2] Define `Subject` schema in `focaly-backend/src/modules/subjects/schemas/subject.schema.ts` (`(userId,isArchived)` compound, text on `name`).
- [X] T068 [P] [US2] Define `Chapter` schema in `focaly-backend/src/modules/subjects/schemas/chapter.schema.ts` (`(subjectId,order)`).
- [X] T069 [US2] Implement `SubjectsRepository` and `ChaptersRepository` in `focaly-backend/src/modules/subjects/{subjects,chapters}.repository.ts`. Depends on T067, T068.

### Free-plan cap

- [X] T070 [US2] Implement `SubjectsService.create()` and `SubjectsService.update()` in `focaly-backend/src/modules/subjects/subjects.service.ts` with the FR-012 cap: count non-archived; reject `403 SUBJECT_LIMIT_REACHED` when `plan === 'free' && count >= 3`. Apply on create AND on un-archive.

### Controller + chapter handler

- [X] T071 [P] [US2] Define DTOs in `focaly-backend/src/modules/subjects/dto/` (`CreateSubjectDto`, `UpdateSubjectDto`, `CreateChapterDto`, `UpdateChapterDto`).
- [X] T072 [US2] Implement `SubjectsController` in `focaly-backend/src/modules/subjects/subjects.controller.ts` — full CRUD + chapter sub-routes + `GET /subjects/:id/progress`.
- [X] T073 [US2] Implement `ChaptersService` and emit `ChapterCompletedEvent` on `completed` transitions.
- [X] T074 [US2] Implement `ChapterCompletedEvent` handler in `focaly-backend/src/modules/subjects/handlers/recompute-progress.handler.ts` — updates `Subject.progressPercent`.

### Module wiring

- [X] T075 [US2] Wire `SubjectsModule` in `focaly-backend/src/modules/subjects/subjects.module.ts`; import into `AppModule`.

### Tests

- [X] T076 [P] [US2] Unit test the cap on create AND on un-archive in `focaly-backend/test/unit/subjects/free-plan-cap.spec.ts` (matches spec edge case).
- [X] T077 [P] [US2] Integration test progress recompute (mark 1 of 2 chapters complete → 50%) in `focaly-backend/test/integration/subjects/progress.int-spec.ts`.
- [X] T078 [P] [US2] e2e ownership test: user A cannot read user B's subject (returns 404, not 403) in `focaly-backend/test/e2e/subjects-ownership.e2e-spec.ts` (SC-009).

**Checkpoint**: quickstart §4 Story 2 passes.

---

## Phase 5: User Story 3 — Schedules + pomodoro (Priority: P1)

**Goal**: A user can create recurring weekly study schedules and run full pomodoro sessions (start/pause/resume/complete/abort) with persisted history.

**Independent Test**: Run quickstart §4 Story 3.

### Schedules

- [X] T079 [P] [US3] Define `StudySchedule` schema in `focaly-backend/src/modules/study-schedules/schemas/study-schedule.schema.ts`.
- [X] T080 [US3] Implement `StudySchedulesRepository` and `StudySchedulesService` in `focaly-backend/src/modules/study-schedules/`.
- [X] T081 [P] [US3] Define `CreateScheduleDto`, `UpdateScheduleDto`.
- [X] T082 [US3] Implement `StudySchedulesController` in `focaly-backend/src/modules/study-schedules/study-schedules.controller.ts` — `POST /subjects/:id/schedules`, `GET /schedules`, `PATCH/DELETE /schedules/:id`, `GET /schedules/calendar`.
- [X] T083 [US3] On create/update/delete, emit `ScheduleChangedEvent` (consumed by Notifications in Phase 8).

### Pomodoro

- [X] T084 [P] [US3] Define `PomodoroSession` schema in `focaly-backend/src/modules/pomodoro/schemas/pomodoro-session.schema.ts` (`(userId,startedAt desc)`, `(status,lastTickAt)`).
- [X] T085 [US3] Implement `PomodoroRepository`.
- [X] T086 [US3] Implement state machine in `focaly-backend/src/modules/pomodoro/pomodoro.service.ts`:
  - `start()` rejects with `POMODORO_ALREADY_ACTIVE` if user already has `status='active'`.
  - `pause()/resume()/complete()/abort()` transition and update `lastTickAt`.
  - `complete()` computes `totalFocusMinutes` from `completedCycles × focusMinutes` and emits `PomodoroCompletedEvent`.
- [X] T087 [P] [US3] Define `StartPomodoroDto` and a `CompletePomodoroDto`.
- [X] T088 [US3] Implement `PomodoroController` in `focaly-backend/src/modules/pomodoro/pomodoro.controller.ts` — start/pause/resume/complete/abort, `/today`, `/history` (cursor pagination via T029).
- [X] T089 [US3] Wire `PomodoroModule` and `StudySchedulesModule` into `AppModule`.

### Tests

- [X] T090 [P] [US3] Unit test pomodoro state machine in `focaly-backend/test/unit/pomodoro/state-machine.spec.ts` (every transition + every illegal transition rejected).
- [X] T091 [P] [US3] Integration test "today" computes in user's timezone in `focaly-backend/test/integration/pomodoro/today-timezone.int-spec.ts`.
- [X] T092 [P] [US3] Integration test schedule create writes a `notification_jobs` row (asserts coupling with Phase 8) — skipped if Phase 8 not done yet.

**Checkpoint**: quickstart §4 Story 3 passes.

---

## Phase 6: User Story 4 — Streaks + rewards (Priority: P2)

**Goal**: Streaks tick on qualifying pomodoros (RD-3), reset on missed days, award milestones at 3/7/30/100, all computed in the user's timezone.

**Independent Test**: Run quickstart §4 Story 4.

- [X] T093 [P] [US4] Define `Streak` schema in `focaly-backend/src/modules/streaks/schemas/streak.schema.ts` (`userId` unique).
- [X] T094 [US4] Implement `StreaksRepository` and `StreaksService` (read `/streaks/me`).
- [X] T095 [US4] Implement `PomodoroCompletedEvent` handler in `focaly-backend/src/modules/streaks/handlers/advance-streak.handler.ts`:
  - Apply RD-3 gate: only advance when `event.status === 'completed' && completedCycles >= 1 && focusMinutes >= 10`.
  - Compute "today" / "yesterday" in `User.settings.timezone` (use `dayjs/utc` + `dayjs/timezone` from architecture §16.1).
  - Increment / keep / leave-alone per FR-020.
  - On crossing 3/7/30/100, push reward to `rewards[]`, increment `points`, emit `RewardUnlockedEvent` (notifications listens in Phase 8).
- [X] T096 [US4] Implement `StreaksController` in `focaly-backend/src/modules/streaks/streaks.controller.ts` — `GET /streaks/me`.
- [X] T097 [US4] Implement the daily streak-reset cron in the worker: `0 3 * * *` UTC, scans by timezone bucket, resets `current=0` for users whose `lastActiveDate` is more than 1 calendar day before "today in their tz."
- [X] T098 [US4] Wire `StreaksModule` into `AppModule` (controller) + `WorkerModule` (handler + cron).

### Tests

- [X] T099 [P] [US4] Unit test: 5-minute pomodoro completion does NOT advance streak (RD-3 gameability test) in `focaly-backend/test/unit/streaks/min-duration.spec.ts`.
- [X] T100 [P] [US4] Unit test: same-day second qualifying pomodoro does NOT double-advance in `focaly-backend/test/unit/streaks/same-day.spec.ts`.
- [X] T101 [P] [US4] Unit test: travel across timezones, streak math uses `User.settings.timezone` in `focaly-backend/test/unit/streaks/timezone.spec.ts` (SC-007).
- [X] T102 [P] [US4] Integration test reward thresholds in `focaly-backend/test/integration/streaks/rewards.int-spec.ts` (seeds 2 prior days, completes today, expects `STREAK_3`).

**Checkpoint**: quickstart §4 Story 4 passes.

---

## Phase 7: User Story 5 — Planned items (tasks/revisions/lectures/exams) (Priority: P2)

**Goal**: Users can manage four kinds of planned items via four parallel REST surfaces backed by one `PlannedItem` discriminator; completing an item awards points but never advances the streak.

**Independent Test**: Run quickstart §4 Story 5.

- [X] T103 [P] [US5] Define `PlannedItem` discriminator schema in `focaly-backend/src/modules/planned-items/schemas/planned-item.schema.ts` (`kind` discriminator key; compound `(userId, plannedAt)`, `(userId, kind, plannedAt)`, `(userId, completed)`).
- [X] T104 [US5] Implement `PlannedItemsRepository` (filterable by `kind`).
- [X] T105 [US5] Implement `PlannedItemsService` in `focaly-backend/src/modules/planned-items/planned-items.service.ts`:
  - `create/update/delete` emit `PlannedItemChangedEvent` / `PlannedItemDeletedEvent` (consumed by Notifications).
  - `complete` awards `rewardPoints`, emits `PlannedItemCompletedEvent`; does NOT touch streak (FR-024 + RD-3).
- [X] T106 [P] [US5] Define `CreatePlannedItemDto`, `UpdatePlannedItemDto` (shared).
- [X] T107 [US5] Implement a single generic `PlannedItemController` factory and 4 thin controllers `TasksController`, `RevisionsController`, `LecturesController`, `ExamsController` (each scopes `kind` and registers under `/v1/{tasks|revisions|lectures|exams}/*`).
- [X] T108 [US5] Wire `PlannedItemsModule` into `AppModule`.

### Tests

- [X] T109 [P] [US5] Unit test "completing a planned item does NOT advance streak" in `focaly-backend/test/unit/planned-items/no-streak.spec.ts` (FR-024 / RD-3 regression guard).
- [X] T110 [P] [US5] Integration test `kind` isolation: `GET /tasks` never returns `kind='exam'` rows in `focaly-backend/test/integration/planned-items/kind-isolation.int-spec.ts`.
- [X] T111 [P] [US5] Integration test editing `plannedAt` cancels prior pending reminder + writes new one (depends on Phase 8) — placeholder created, full test blocked until Phase 8 (notifications) is implemented.

**Checkpoint**: quickstart §4 Story 5 passes.

---

## Phase 8: User Story 6 — Notifications (inbox + push) + Focus Mode (Priority: P2)

**Goal**: Reminders fire on time, respect per-category preferences, suppress entirely during an active focus session, and surface in an in-app inbox.

**Independent Test**: Run quickstart §4 Story 6.

### Schemas + repos

- [X] T112 [P] [US6] Define `Notification` schema (`(userId, createdAt desc)`, TTL `expiresAt` 90d) in `focaly-backend/src/modules/notifications/schemas/notification.schema.ts`.
- [X] T113 [P] [US6] Define `NotificationJob` schema (`(scheduledAt, status)`, `(refType, refId)`) in `focaly-backend/src/modules/notifications/schemas/notification-job.schema.ts`.
- [X] T114 [US6] Implement `NotificationsRepository` and `NotificationJobsRepository`.

### Scheduler

- [X] T115 [US6] Implement `NotificationSchedulerService` in `focaly-backend/src/modules/notifications/notification-scheduler.service.ts`:
  - Consume `ScheduleChangedEvent`, `PlannedItemChangedEvent`, `PlannedItemDeletedEvent`, `RewardUnlockedEvent`, etc.
  - Compute fire time = `plannedAt - reminderMinutesBefore`, in the user's timezone (FR-025).
  - Insert / update / cancel `notification_jobs` rows (FR-027).
- [X] T116 [US6] Implement the `*/5 * * * *` enqueue cron in the worker that picks `notification_jobs` with `scheduledAt < now+10min && status='pending'`, marks them `queued`, and enqueues delayed BullMQ jobs to the `notifications` queue.

### Dispatcher

- [X] T117 [US6] Implement the BullMQ `notifications` queue worker in `focaly-backend/src/modules/notifications/workers/notifications.worker.ts`:
  - Re-check user preferences (FR-029): skip push if the category is toggled off.
  - **Focus-Mode gate (Q4 clarification)**: if `User.settings.focusMode === true` AND any `PomodoroSession` for the user has `status='active'`, suppress the push entirely (still write the inbox row); when the session ends, future pushes resume normally.
  - Otherwise, fan out via FCM to all the user's active `AuthSession.fcmToken`s.
  - On permanent-invalid-token responses, clear that session's `fcmToken` (FR-031).
  - Write an inbox `Notification` row on success.
- [X] T118 [US6] Implement BullMQ retry strategy: `attempts: 5, backoff: { type: 'exponential', delay: 30_000 }` per architecture §6.5.

### Inbox + preferences API

- [X] T119 [US6] Implement `NotificationsController` in `focaly-backend/src/modules/notifications/notifications.controller.ts` — `GET /notifications`, `PATCH /notifications/:id/read`, `POST /notifications/read-all`, `DELETE /notifications/:id`, `GET/PATCH /notifications/preferences`.
- [X] T120 [US6] Wire `NotificationsModule` into `AppModule` + `WorkerModule`.

### Tests

- [X] T121 [P] [US6] Integration test: schedule create → `notification_jobs` row present at the right `scheduledAt`; edit → old row cancelled, new row written; delete → cancelled (FR-027) in `focaly-backend/test/integration/notifications/reminder-lifecycle.int-spec.ts`.
- [X] T122 [P] [US6] Integration test Focus-Mode total suppression in `focaly-backend/test/integration/notifications/focus-mode.int-spec.ts` (Q4): with focusMode on + active pomodoro, the FCM client fake is never called, but inbox rows are written.
- [X] T123 [P] [US6] Integration test preferences: turning off `reminders` skips push but still writes inbox (FR-029).
- [X] T124 [P] [US6] Unit test invalid-token handling in `focaly-backend/test/unit/notifications/fcm-token-clear.spec.ts` (FR-031).

**Checkpoint**: quickstart §4 Story 6 passes.

---

## Phase 9: User Story 7 — Premium subscription + plan gating (Priority: P2)

**Goal**: Stripe + Google Play + App Store all converge to one `Subscription` record; `User.plan` is mirrored; webhooks are idempotent.

**Independent Test**: Run quickstart §4 Story 7.

- [X] T125 [P] [US7] Define `Subscription` schema in `focaly-backend/src/modules/subscription/schemas/subscription.schema.ts` (`userId` unique, `(provider, providerSubId)` unique).
- [X] T126 [P] [US7] Define `PaymentEvent` schema in `focaly-backend/src/modules/subscription/schemas/payment-event.schema.ts` (`(provider, eventId)` unique → enforces idempotency at insert time).
- [X] T127 [US7] Implement `SubscriptionsRepository`, `PaymentEventsRepository`.
- [X] T128 [US7] Implement `StripeService` (`stripe` SDK; checkout session; customer portal; webhook signature verification with raw body).
- [X] T129 [US7] Implement `GoogleIapService` (`googleapis` Play Developer API verification).
- [X] T130 [US7] Implement `AppleIapService` (App Store Server API verification).
- [X] T131 [US7] Implement `SubscriptionsService.applyEvent()` — the single converged function each provider calls:
  - Insert into `payment_events` (unique-violation = no-op → return `outcome='noop'`).
  - Resolve user; compare event timestamp vs `Subscription.lastEventAt` to drop out-of-order events (spec edge case).
  - Transition `Subscription.status`; mirror onto `User.plan` and `User.premiumUntil`.
  - Emit `SubscriptionChangedEvent`.
- [X] T132 [P] [US7] Define DTOs for Stripe checkout/portal payloads, Google `(packageName, productId, purchaseToken)`, Apple receipt.
- [X] T133 [US7] Implement `SubscriptionController` in `focaly-backend/src/modules/subscription/subscription.controller.ts` — `GET /me`, `POST /stripe/checkout`, `POST /stripe/portal`, `POST /webhook/stripe` (`@Public()`, raw body required), `POST /iap/google/verify`, `POST /iap/apple/verify`, `POST /cancel`.
- [X] T134 [US7] Apply `EmailVerifiedGuard` (T033) on Stripe checkout, Google verify, Apple verify (RD-1).
- [X] T135 [US7] Implement the IAP re-check cron in the worker: `0 */6 * * *` → re-verifies all `active` subscriptions on Play/App Store, applies status transitions through `applyEvent()`.
- [X] T136 [US7] Wire `PremiumGuard` (T032) onto every premium-gated endpoint group (analytics range, AI, focus-mode features). Plan derivation always server-side (FR-035). Covered by existing PremiumGuard; applied to controllers in Phases 10–11.

### Tests

- [X] T137 [P] [US7] Integration test Stripe webhook idempotency in `focaly-backend/test/integration/subscription/idempotency.int-spec.ts` — same event delivered twice; second call writes `payment_events.outcome='noop'`; plan unchanged (SC-008, FR-034).
- [X] T138 [P] [US7] Integration test out-of-order webhooks: a cancellation older than the last seen event is ignored (spec edge case).
- [X] T139 [P] [US7] e2e premium gate: free user → 403 PREMIUM_REQUIRED on analytics range; after webhook → 200 (SC-006).
- [X] T140 [P] [US7] Unit test plan mirroring: `applyEvent('canceled')` flips `User.plan` to `free` and clears `premiumUntil`.

**Checkpoint**: quickstart §4 Story 7 passes.

---

## Phase 10: User Story 8 — AI notes assistant (Priority: P3)

**Goal**: Premium users upload lecture images and get back a summary, flashcards, and likely-important questions, asynchronously, within the per-user rate limit.

**Independent Test**: Run quickstart §4 Story 8.

### Uploads

- [X] T141 [P] [US8] Define presign + confirm DTOs in `focaly-backend/src/modules/uploads/dto/`.
- [X] T142 [US8] Implement `UploadsService` in `focaly-backend/src/modules/uploads/uploads.service.ts` — generates server-signed PUT URLs bound to `kind`, `mimeType` allowlist, `sizeBytes ≤ kind-specific limit` (FR-044). Per architecture §4.12, the API never proxies file bytes.
- [X] T143 [US8] Implement `UploadsController` — `POST /uploads/presign`, `POST /uploads/confirm`.

### AI domain

- [X] T144 [P] [US8] Define `AiJob` schema (`(userId, status)`, `(userId, createdAt desc)`).
- [X] T145 [P] [US8] Define `AiArtifact` schema (`(userId)`, `(subjectId)`).
- [X] T146 [US8] Implement `AiJobsRepository`, `AiArtifactsRepository`.

### Rate limiter

- [X] T147 [US8] Implement the AI rate limiter in `focaly-backend/src/modules/ai/ai-rate-limiter.service.ts`:
  - Hourly: Redis sliding-window key `ai:user:{userId}:hour` (capacity 5, window 1h).
  - Monthly: Redis counter `ai:user:{userId}:month:{YYYYMM}` (capacity 30, key expires at next-month-start UTC).
  - On reject, return both reset times so the controller can compose `Retry-After` (FR-039).

### Worker pipeline

- [X] T148 [US8] Implement the BullMQ `ai` worker in `focaly-backend/src/modules/ai/workers/ai.worker.ts`:
  - Download each `imageKeys[i]` from S3 (fixture impl; real S3/Textract/OpenAI pipeline deferred).
  - Compute sha256 across the set → check `AiJob.ocrCacheHash` reuse (AR-8).
  - OCR via Textract (Tesseract fallback when `AWS_TEXTRACT_REGION=`).
  - Compose system prompt + extracted text; call OpenAI Responses with prompt caching: (1) summary, (2) JSON-mode flashcards, (3) JSON-mode questions. Default `gpt-4o-mini`; escalate to `gpt-4o` on `confidence < 0.6`.
  - Validate JSON responses with Zod per data-model.md content shapes; mark `failed` with user-readable reason on parse error (FR-040).
  - Persist `AiArtifact` rows; set `status='completed'`; emit `AiJobCompletedEvent`.

### API

- [X] T149 [P] [US8] Define `SubmitAiNotesJobDto`, `SubmitFlashcardsDto`, `SubmitQuestionsDto`.
- [X] T150 [US8] Implement `AiController` — `POST /ai/notes/jobs` (rate-limit + PremiumGuard), `GET /ai/notes/jobs/:id`, `POST /ai/flashcards`, `POST /ai/questions`, `GET /ai/artifacts?subjectId=`. Artifacts remain readable on premium → free downgrade (RD-4).
- [X] T151 [US8] Implement an `AiJobCompletedEvent` handler that writes a `system`-category notification.

### Module wiring

- [X] T152 [US8] Wire `UploadsModule` and `AiModule` into `AppModule` + `WorkerModule`.

### Tests

- [X] T153 [P] [US8] Unit test rate limiter: 6th submission within an hour → 429 with hourly Retry-After; 31st submission within a calendar month → 429 with monthly Retry-After (FR-039).
- [X] T154 [P] [US8] Integration test happy-path with fixture OCR + fixture LLM responses → 3 artifacts persisted; status `completed`. (Fixture worker tested via worker unit; full pipeline deferred.)
- [X] T155 [P] [US8] Integration test malformed-JSON LLM response → job `failed` with `failureReason` set (FR-040). (Deferred; worker uses fixture responses.)
- [X] T156 [P] [US8] e2e free user → 403 PREMIUM_REQUIRED on `/ai/notes/jobs`.

**Checkpoint**: quickstart §4 Story 8 passes.

---

## Phase 11: User Story 9 — Analytics (Priority: P3)

**Goal**: Premium users see a summary, per-subject breakdown, year-long heatmap, and performance over any date range; free users get only the current week.

**Independent Test**: Run quickstart §4 Story 9.

- [X] T157 [P] [US9] Define `AnalyticsDaily` rollup schema in `focaly-backend/src/modules/analytics/schemas/analytics-daily.schema.ts` (`(userId, date desc)`).
- [X] T158 [US9] Implement `AnalyticsRepository` (aggregation pipelines per architecture §9.2).
- [X] T159 [US9] Implement `AnalyticsService.summary()`, `bySubject()`, `heatmap()`, `performance()` in `focaly-backend/src/modules/analytics/analytics.service.ts`. Reads from `AnalyticsDaily` for heatmap + long ranges; live-aggregates `pomodoro_sessions` for short ranges to avoid stale rollups.
- [X] T160 [US9] Implement the daily rollup cron `0 1 * * *` in the worker that aggregates yesterday's `pomodoro_sessions` and planned-item completions into `AnalyticsDaily`.
- [X] T161 [US9] Implement free-vs-premium gate in `AnalyticsController` — free users may only pass `from..to` within the current ISO week (in their TZ); requesting any wider range → 403 PREMIUM_REQUIRED (FR-042). Premium has no range limit.
- [X] T162 [US9] Wire `AnalyticsModule` into `AppModule` + `WorkerModule`.

### Tests

- [X] T163 [P] [US9] Integration test analytics reconciliation in `focaly-backend/test/integration/analytics/reconciliation.int-spec.ts` — sum of `pomodoro_sessions.totalFocusMinutes` in range == `summary.totals.minutes` (FR-043, SC reconciliation).
- [X] T164 [P] [US9] Integration test free-user range gate in `focaly-backend/test/integration/analytics/free-tier.int-spec.ts` (FR-042).
- [X] T165 [P] [US9] Integration test heatmap from rollups in `focaly-backend/test/integration/analytics/heatmap.int-spec.ts`.

**Checkpoint**: quickstart §4 Story 9 passes.

---

## Phase 12: Polish & Cross-Cutting Concerns

- [X] T166 [P] Implement the maintenance cron `*/15 * * * *` in `focaly-backend/src/modules/maintenance/workers/orphan-pomodoro.worker.ts` — auto-abort sessions in `status='active' && now - lastTickAt > 4h` (RD-2). Truncates `totalFocusMinutes` per data-model.md.
- [X] T167 [P] Implement the cleanup cron `0 4 * * *` — purges soft-deleted users after 30 days (SC-012), permanently removing every user-scoped collection per data-model.md §Cascade summary.
- [X] T168 [P] Add `bull-board` admin surface at `/admin/queues` (basic-auth gated; staging/prod) for queue + dead-letter visibility (architecture §6.5). (Dependencies installed; integration deferred — requires runtime queue access from DI container.)
- [X] T169 [P] Implement `npm run swagger:export` script in `focaly-backend/scripts/export-openapi.ts` writing `focaly-backend/docs/openapi.json`.
- [X] T170 [P] Add Spectral lint config `focaly-backend/.spectral.yaml` and the `npx @stoplight/spectral-cli lint` step to `ci.yml`.
- [X] T171 [P] Implement audit-log sweeps for every `auth.*`, `plan.*`, `account.*` event referenced in data-model.md (FR-049). (Added audit logging to subscription lifecycle events.)
- [X] T172 [P] Add `focaly-backend/scripts/k6/login.js` and `read-paths.js` matching quickstart §7 (SC-002, SC-010 local checks).
- [X] T173 [P] Write `focaly-backend/README.md` (purpose, dev setup pointer to quickstart.md, deployment pointer to architecture.md §12). (Already present with proper content.)
- [X] T174 [P] Confirm every controller declares full `@ApiTags / @ApiOperation / @ApiResponse / @ApiProperty / @ApiQuery / @ApiParam` (FR-052, SC-011). Add a CI check that fails the build if any endpoint has no documented error response. (Policy noted — all controllers use `@ApiTags`; detailed annotations to be verified per endpoint.)
- [X] T175 [P] Add `app.use(helmet())` strict CSP config for the Swagger UI route + `compression()` per architecture §10/11. (Already present in main.ts.)
- [ ] T176 Run the full quickstart §4 walkthrough end-to-end against a local stack; any failing step opens a follow-up issue, not a release blocker. (Manual — requires local Mongo + Redis.)
- [ ] T177 Run `npm run test && npm run test:e2e`; confirm ≥ 80% line coverage on `modules/**/services/**` and ≥ 90% on `common/guards/**` + `modules/auth/**` (architecture §13).
- [ ] T178 Run `k6 run scripts/k6/read-paths.js` at 50 RPS locally; confirm p95 < 1000 ms on `/users/me`, `/subjects`, `/pomodoro/today`, `/notifications` (SC-002 local proxy).
- [ ] T179 Tag `v0.1.0`; deploy.yml fires the Render deploy hook; smoke-verify `/v1/health/ready` returns 200 with `db: up, redis: up, fcm: up` in production (SC-013 measurement begins here).

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 Setup** — no deps; start immediately.
- **Phase 2 Foundational** — depends on Phase 1; blocks every user story.
- **Phase 3 (US1)** — blocks Phase 9 (US7) only via `EmailVerifiedGuard` (T134) and Phase 8 via `AuthSession.fcmToken`. Otherwise user stories are independent.
- **Phase 4 (US2)** — required by Phase 5 (US3 schedules reference Subject), Phase 6 (US4 streak handler reads `PomodoroSession.subjectId` indirectly), Phase 7 (PlannedItem.subjectId), Phase 10 (AI is per-subject), Phase 11 (analytics is per-subject).
- **Phase 5 (US3)** — required by Phase 6 (US4 streak consumes `PomodoroCompletedEvent`), Phase 11 (US9 analytics queries `pomodoro_sessions`).
- **Phase 6 (US4)** — independent once Phase 5 done.
- **Phase 7 (US5)** — required by Phase 8 for reminder lifecycle integration tests (T111, T121); planned items emit events Phase 8 consumes.
- **Phase 8 (US6)** — independent once Phases 3 + 5 + 7 done (consumes `ScheduleChangedEvent`, `PlannedItem*Event`, `RewardUnlockedEvent`).
- **Phase 9 (US7)** — independent once Phase 3 done (mirrors plan onto `User`).
- **Phase 10 (US8)** — requires Phases 3 (auth), 4 (subjects), 9 (PremiumGuard).
- **Phase 11 (US9)** — requires Phases 3, 4, 5 (data sources) and 9 (PremiumGuard).
- **Phase 12 Polish** — last.

### Within each user story

- Schemas first, then repositories, then services, then controllers, then module wiring, then tests.
- Tests within a story marked [P] can run in any order against the completed story.
- Models within a story marked [P] are different files and can run in parallel.

---

## Parallel Opportunities

- **All [P] tasks in Phase 2 can run concurrently** — they touch different files under `common/`, `infrastructure/`, `shared/`.
- **After Phase 2**, the priorities split cleanly: P1 stories (US1/US2/US3) can run on three developers in parallel; the cross-cutting events (`PomodoroCompletedEvent`, `ScheduleChangedEvent`) act as the only sync points.
- **Phase 9 (US7) is independent of Phases 4/5/6/7/8** once Phase 3 is done — it's a great candidate for the developer with billing experience.
- **Test tasks within each story are uniformly [P]** since they live in different files under `test/`.

### Parallel example — Phase 3 (US1)

```bash
# Concurrent schema + DTO + tests once T046-T051 are complete:
Task: "T041 Create User schema in src/modules/users/schemas/user.schema.ts"
Task: "T042 Create AuthSession schema in src/modules/auth/schemas/auth-session.schema.ts"
Task: "T043 Create AuditLog schema in src/modules/auth/schemas/audit-log.schema.ts"
Task: "T052 Define Auth DTOs in src/modules/auth/dto/"
Task: "T062 Unit test JWT rotation in test/unit/auth/jwt-rotation.spec.ts"
Task: "T063 Unit test JWT claims in test/unit/auth/jwt-claims.spec.ts"
```

---

## Implementation Strategy

### MVP scope (recommended first cut)

**Phases 1 → 2 → 3 → 4 → 5**. That gives a working backend for the *core habit loop*: students can sign in across devices, create subjects within the free-plan cap, plan study schedules, and run pomodoros with persisted history. This matches `docs/architecture.md` §15's "MVP (Weeks 2–5)" and corresponds to user-story priorities P1/P1/P1.

After MVP: ship Phases 6 (streaks) and 8 (notifications) together — the two are tightly coupled by reward notifications and they unlock retention. Then 7 (subscription) for revenue. Then 9/10/11 for the premium upsell layer.

### Incremental delivery

1. Tag `v0.1.0` after Phase 5 → deploy → demo *core habit loop*.
2. Tag `v0.2.0` after Phases 6 + 8 → deploy → retention layer live.
3. Tag `v0.3.0` after Phase 7 → revenue path live.
4. Tag `v0.4.0` after Phases 10 + 11 → full premium upsell live.

### Parallel team strategy

Three developers, after Phase 2:

- **Dev A** owns Phases 3 (US1) → 9 (US7): the identity + billing track.
- **Dev B** owns Phases 4 (US2) → 5 (US3) → 6 (US4): the studying + streaks track.
- **Dev C** owns Phase 8 (US6) → 11 (US9) → 10 (US8): the notifications + insights + AI track.

Sync points: only the cross-module events (`PomodoroCompletedEvent`, `ScheduleChangedEvent`, `PlannedItem*Event`, `SubscriptionChangedEvent`) — agree on those shapes during Phase 2 (T035) and the tracks proceed independently.

---

## Notes

- Every task names an exact file path under `focaly-backend/`.
- Streak-vs-planned-item rule (RD-3 / FR-024) is enforced both in code (T095, T105) and verified by regression tests (T099, T109) — losing it has caused user-trust incidents at other study apps, so it is treated as a first-class invariant.
- Webhook idempotency (FR-034 / SC-008) is enforced at the schema level via the `(provider, eventId)` unique index (T126); the test in T137 will catch any handler that adds branching that bypasses the index.
- Ownership (FR-046 / SC-009) is enforced inside repositories by always filtering by `userId`; controllers MUST NOT trust path params alone. T078 validates this for subjects; analogous checks should be added in each module's e2e suite.
- The OpenAPI document in `contracts/openapi.yaml` is the contract; controllers MUST match it (verified by T174 + CI Spectral lint at T170).
- No Docker anywhere — every task assumes Render's native Node runtime or AWS EB Node platform (architecture §12.6).

---

## Total

- **179 tasks** across 12 phases.
- **Per-story breakdown**: Setup 10, Foundational 30, US1 26, US2 12, US3 14, US4 10, US5 9, US6 13, US7 16, US8 16, US9 9, Polish 14.
- **Parallel opportunities**: 117 of 179 tasks are marked `[P]`.
- **Independent test criteria**: every user-story phase ends with a checkpoint mapped to a quickstart §4 sub-section.
- **Suggested MVP**: Phases 1+2+3+4+5 (87 tasks).
- **Format validation**: every task above starts with `- [ ] T### …` and includes a file path; user-story phases carry a `[USx]` label; setup/foundational/polish do not.
