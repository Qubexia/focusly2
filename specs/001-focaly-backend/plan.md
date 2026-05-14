# Implementation Plan: Focaly Backend — Study Management Platform

**Branch**: `001-focaly-backend` | **Date**: 2026-05-14 | **Spec**: [./spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-focaly-backend/spec.md`
**Reference architecture**: [/docs/architecture.md](../../docs/architecture.md) — the project's pre-existing senior-level backend architecture document. This plan does not re-invent it; it formalizes the choices, maps them to the spec's user stories, and identifies what still needs research vs. what is decided.

## Summary

Build a modular-monolith backend for the Focaly Study Management Mobile App that powers all 9 user stories in the spec (auth, subjects/chapters with free-plan cap, study schedules, pomodoro, streaks, planned items, notifications, premium gating, AI notes, analytics) while meeting the spec's non-functional targets (99.5% availability SLO, sub-1s perceived read latency, 99% reminders within 60s of fire time, 10k concurrent users / 1k RPS hot paths, 15-min access + 30-day rotating refresh credentials, 5/hour and 30/month AI rate limits).

**Technical approach** (carried over from `docs/architecture.md`): NestJS modular monolith over MongoDB + Redis with BullMQ for async work, Firebase Cloud Messaging for push, Stripe + Google Play + App Store for billing, OpenAI + AWS Textract for AI features, deployed on Render (MVP) without Docker — a second worker service on the same source consumes BullMQ queues. Each feature module follows a 4-layer clean architecture (presentation / application / domain / infrastructure) and emits domain events via NestJS CQRS for fan-out (e.g., `PomodoroCompletedEvent` → streaks + analytics + notifications). Swagger UI is the primary API testing surface.

## Technical Context

**Language/Version**: TypeScript 5.x on Node.js 20 LTS (Render & AWS EB Node platform both support 20+).
**Primary Dependencies**: `@nestjs/{common,core,config,jwt,passport,mongoose,bullmq,schedule,swagger,terminus,cqrs,throttler}`, `mongoose`, `class-validator`, `class-transformer`, `bullmq`, `ioredis`, `firebase-admin`, `stripe`, `google-auth-library`, `argon2`, `dayjs`, `rrule`, `zod`, `openai`, `@aws-sdk/client-s3`, `@aws-sdk/client-textract`, `nestjs-pino`, `@sentry/node`, `@opentelemetry/*`, `helmet`, `compression`. Full list in `docs/architecture.md` §16.1.
**Storage**: MongoDB (managed: MongoDB Atlas) for primary state; Redis (managed: Upstash) for cache, rate-limit windows, throttler store, and BullMQ broker; S3 for uploaded files (avatars, lecture images).
**Testing**: Jest (unit + integration), `supertest` (e2e HTTP), `mongodb-memory-server` (integration Mongo), `ioredis-mock` (integration Redis), Pact (mobile↔backend contract snapshot of the OpenAPI document), k6 (load smoke on hot paths). Coverage targets: ≥80% on services, ≥90% on guards/auth.
**Target Platform**: Render (MVP) — one Node Web Service + one Background Worker service; AWS Elastic Beanstalk Node platform + ElastiCache + Atlas at scale. **No Docker** at any tier (constraint from `docs/architecture.md` §12).
**Project Type**: Backend API for a mobile-first client (no web frontend in scope; admin UI is out of scope per spec assumptions).
**Performance Goals**: p95 < 1 s perceived latency on read-heavy endpoints (spec SC-002); sustain 10k concurrent users and 1k RPS on hot read paths (spec SC-010); 99% of scheduled reminders fire within 60 s of intended time (spec SC-003); AI jobs complete or surface failure within 3 min (spec SC-005).
**Constraints**: 99.5% monthly availability SLO measured at the API gateway (spec SC-013); 15-min short-lived access credential + 30-day rotating long-lived credential (spec FR-005); AI rate limit 5/hour, 30/month/user (spec FR-039); ownership enforcement on every authenticated endpoint (spec FR-046); single consistent error envelope `{ code, message, details? }` (spec FR-047); no Docker on any deployment target.
**Scale/Scope**: ~50 endpoints across 16 module surfaces; ~20 Mongo collections (full list in `docs/architecture.md` §2.1); 5 BullMQ queues (`notifications`, `ai`, `analytics`, `subscription`, `maintenance`); 5 scheduled crons (`*/5 * * * *` reminder enqueue, daily analytics rollup, daily streak maintenance, daily cleanup, 6-hourly IAP recheck); MVP target 10k concurrent / 1k RPS, headroom to grow via stateless horizontal scaling.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project's `.specify/memory/constitution.md` contains only template placeholders — no principles have been ratified. There are therefore no constitution-imposed gates to evaluate.

Proceeding under inline industry-standard practices drawn from `docs/architecture.md`:

- Clean architecture per module (4 layers: presentation/application/domain/infrastructure).
- Repository abstraction inside each module (no Mongoose leaking into services).
- Domain events via NestJS CQRS for cross-module fan-out (no direct module-to-module imports).
- Global validation pipe (`whitelist + forbidNonWhitelisted + transform`), global exception filter producing the single error envelope, global logging interceptor with request-id correlation.
- Test-first on guards and on streak/subscription math (the two areas where regressions are most costly).
- Swagger UI as the primary manual testing surface (`persistAuthorization: true`).

**Gate verdict**: PASS (no ratified principles to violate). When the constitution is later ratified, re-run `/speckit.plan` to re-evaluate.

## Project Structure

### Documentation (this feature)

```text
specs/001-focaly-backend/
├── plan.md              # This file
├── research.md          # Phase 0 output — decisions, rationale, alternatives
├── data-model.md        # Phase 1 output — entities, relationships, state machines
├── quickstart.md        # Phase 1 output — local dev setup + verification steps
├── contracts/
│   └── openapi.yaml     # Phase 1 output — API contract (one tag per module)
├── checklists/
│   └── requirements.md  # From /speckit.specify
└── tasks.md             # NOT created here — produced by /speckit.tasks
```

### Source Code (repository root)

The implementation lives at the repository root under `focaly-backend/`, exactly as `docs/architecture.md` §1.3 prescribes. Two entry points share the same source: `dist/main.js` (Web Service) and `dist/worker.js` (Background Worker).

```text
focaly-backend/
├── src/
│   ├── main.ts                              # API entry
│   ├── worker.ts                            # Worker entry (BullMQ consumers + schedule)
│   ├── app.module.ts
│   ├── config/                              # @nestjs/config + Joi validation
│   │   ├── configuration.ts
│   │   ├── validation.schema.ts
│   │   └── env/{app,db,redis,jwt,fcm,openai,stripe}.config.ts
│   ├── common/                              # cross-cutting
│   │   ├── decorators/                      # @CurrentUser, @Public, @Roles, @Premium, @Idempotent
│   │   ├── filters/                         # AllExceptionsFilter (single envelope), MongoExceptionFilter
│   │   ├── interceptors/                    # LoggingInterceptor, TransformInterceptor, CacheInterceptor
│   │   ├── pipes/                           # ParseObjectIdPipe, ValidationPipe
│   │   ├── guards/                          # JwtAuthGuard, JwtRefreshGuard, RolesGuard, PremiumGuard, ThrottlerBehindProxyGuard
│   │   ├── middleware/                      # RequestIdMiddleware, AuditLogMiddleware
│   │   ├── dto/                             # PaginationDto, DateRangeDto, ApiResponse
│   │   ├── utils/                           # date (TZ-aware), hash, ids
│   │   └── constants/
│   ├── modules/                             # 16 feature modules, each independently testable
│   │   ├── auth/                            # US1
│   │   ├── users/                           # US1 (profile), FR-008/9/10
│   │   ├── subjects/                        # US2
│   │   ├── study-schedules/                 # US3 (schedules), US5 fan-in for reminders
│   │   ├── pomodoro/                        # US3 + emits PomodoroCompletedEvent (streak source)
│   │   ├── streaks/                         # US4 — consumes PomodoroCompletedEvent
│   │   ├── tasks/                           # US5 — PlannedItem discriminator
│   │   ├── revisions/                       # US5
│   │   ├── lectures/                        # US5
│   │   ├── exams/                           # US5
│   │   ├── notifications/                   # US6 (inbox + push + scheduler)
│   │   ├── analytics/                       # US9 — premium-gated
│   │   ├── subscription/                    # US7 — stripe + google_play + app_store convergence
│   │   ├── ai/                              # US8 — premium-gated, queue-driven
│   │   ├── uploads/                         # US8 support (presigned PUT)
│   │   └── health/                          # FR-050
│   ├── infrastructure/
│   │   ├── database/                        # mongoose root module + migrations
│   │   ├── redis/
│   │   ├── queue/                           # BullMQ shared module
│   │   ├── fcm/                             # firebase-admin client
│   │   ├── storage/                         # S3 client
│   │   ├── mailer/                          # SES/SendGrid
│   │   ├── logger/                          # pino
│   │   └── tracing/                         # OpenTelemetry
│   └── shared/
│       ├── events/                          # EventBus (Nest CQRS) — internal events
│       └── types/
├── test/
│   ├── unit/                                # services, guards, mappers
│   ├── integration/                         # controller ↔ service ↔ real Mongo (memory-server)
│   └── e2e/                                 # full HTTP via supertest
├── .github/workflows/
│   ├── ci.yml                               # lint → typecheck → unit → integration → build
│   └── deploy.yml                           # on tag v* → Render deploy hook (no image build)
├── scripts/
│   ├── seed.ts
│   └── migrate.ts
├── docs/
│   └── openapi.json                         # exported in CI
├── .env.example
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
├── package.json
├── README.md
└── render.yaml                              # Render service definitions (web + worker)
```

**Structure Decision**: Single backend project, modular monolith — matches `docs/architecture.md` §1.1's explicit decision against microservices for MVP, with clear module borders so workers can be carved out later (`notifications-worker`, `ai-worker`, `analytics-worker`) without rewriting business logic. No `frontend/` directory: the mobile client lives in a separate repository, consumes the OpenAPI schema exported in CI, and is not part of this feature's scope.

## Module ↔ Story Mapping

| User Story | Owning module(s) | Cross-module events consumed |
|---|---|---|
| US1 Auth + multi-device sessions | `auth`, `users` | — |
| US2 Subjects + chapters + free-plan cap | `subjects` | `chapter.completed` → updates Subject.progressPercent |
| US3 Schedules + pomodoro | `study-schedules`, `pomodoro` | — |
| US4 Streaks + rewards | `streaks` | `PomodoroCompletedEvent` |
| US5 Planned items + reminders | `tasks`, `revisions`, `lectures`, `exams` (all on `PlannedItem` discriminator) | — |
| US6 Notifications (inbox + push) | `notifications` | All upstream events that produce reminders or system messages |
| US7 Premium + billing | `subscription`, `users` (plan mirror), `common/guards/PremiumGuard` | Stripe / Google Play / App Store webhooks |
| US8 AI notes assistant | `ai`, `uploads`, BullMQ `ai` queue | Emits `AiJobCompletedEvent` → notifications |
| US9 Analytics | `analytics` (premium-gated) | Daily rollup cron + on-write counters |

## Phase 0: Outline & Research

**Output**: [research.md](./research.md) — see file for full decision table.

Most macro-level technical decisions are already made in `docs/architecture.md` and are not re-litigated here. Phase 0 focuses on the *open questions* — items the spec did not pin or `docs/architecture.md` left as alternatives. Each gets a decision, a rationale, and recorded alternatives.

Open items from the spec (not blocking, but flagged for research before implementation):

1. **Email verification gating behavior** (FR-002) — spec did not pin whether unverified users have full access. Round-2 clarification not answered. Defaulted in `research.md` to "soft gate" (full access; verification required only for password change, email change, and subscription purchase) as the lowest-friction industry-standard pattern.
2. **Pomodoro orphan timeout** (edge case — "left active for an unreasonable duration") — spec mentions the requirement but no threshold. Defaulted in `research.md` to: auto-abort any session in `status = active` for more than 4 hours (longest reasonable single-sitting study run).
3. **Minimum focus duration for streak qualification** (FR-020) — `completedCycles ≥ 1` but cycle duration is configurable. Defaulted in `research.md` to: a cycle counts only if its configured `focusMinutes ≥ 10` (any pomodoro configured at < 10 min focus does not qualify for streaks, preventing gameability).
4. **AI artifact retention** (no FR) — defaulted in `research.md` to: artifacts persist as long as the user account exists; users keep them on premium → free downgrade (paid for them once); deleted with the account on the 30-day purge.

Technology decisions consolidated from `docs/architecture.md` and re-affirmed in `research.md`:

- **Modular monolith vs microservices** → modular monolith (architecture §1.1).
- **MongoDB vs Postgres** → MongoDB (architecture §2; user-scoped document patterns, flexible PlannedItem discriminator).
- **BullMQ vs SQS for async** → BullMQ (architecture §6.1; already need Redis for caching/throttling).
- **OCR provider** → AWS Textract for handwriting/tables, Tesseract local-dev fallback (architecture §8.2).
- **LLM** → OpenAI Responses API, default `gpt-4o-mini`, escalate to `gpt-4o` on low-confidence outputs (architecture §8.3).
- **Push** → Firebase Cloud Messaging (architecture §6.1), with per-device token storage on `auth_sessions` to enable multi-device fan-out.
- **JWT signing** → RS256 with quarterly key rotation (architecture §5.1).
- **No Docker** → Render Node runtime build, plain `node dist/main.js` start (architecture §12.6).

## Phase 1: Design & Contracts

**Output**: [data-model.md](./data-model.md), [contracts/openapi.yaml](./contracts/openapi.yaml), [quickstart.md](./quickstart.md).

### Data model (data-model.md)

Mirrors `docs/architecture.md` §2 entity-by-entity, formalized against the spec's 14 Key Entities. The discriminator on `PlannedItem` (kind ∈ {task, revision, lecture, exam}) collapses four user-facing collections into one storage shape. The `Streak` record is a single doc per user; `last_active_local_date` is recorded as a `YYYY-MM-DD` string in the user's timezone (per spec FR-020 + Q1 clarification). The `Subscription` record is the single source of truth for plan state across all three billing providers (FR-032/33); `User.plan` and `User.premiumUntil` are mirrored for fast per-request checks (FR-035). Compound indexes follow the rule "every `userId + <sort/filter field>`"; TTL indexes drive automatic purge of inbox (90d), audit (365d), and auth_sessions (`expiresAt`).

State machines that the data model formalizes:

- `PomodoroSession.status`: `active → paused → active → completed | aborted`. Auto-abort on >4h in `active` (research decision RD-2).
- `NotificationJob.status`: `pending → queued → sent | failed | cancelled`.
- `Subscription.status`: `trialing | active → past_due → canceled | expired` (provider-driven).
- `AiJob.status`: `queued → processing → completed | failed`.

### API contract (contracts/openapi.yaml)

One OpenAPI 3.1 document, one tag per module (matching the 16 modules), URI-versioned under `/v1/...`. Every endpoint declares its success-response schema and the documented error shapes (400/401/403/404/409/422/429). Bearer auth is the global security requirement (FR-005, FR-046); `@Public()` exceptions are explicitly annotated. The error envelope is registered once as a shared component and referenced from every error response.

Endpoint surface follows `docs/architecture.md` §4 verbatim. Premium-gated endpoints (analytics date-range, AI, focus-mode) carry the `Premium` scope marker in their description. AI rate-limit responses include `Retry-After` (FR-039).

### Quickstart (quickstart.md)

Local-dev setup, then a verification script that walks the 9-user-story acceptance scenarios end-to-end via Swagger UI (no Postman). Matches `docs/architecture.md` §"Verification" — register/verify/login, free-plan cap, schedule + reminder, pomodoro → streak → analytics, premium gate, AI job, multipart upload, error shapes, health, load smoke.

### Agent context update

Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude` to refresh `CLAUDE.md` with this feature's technology context (TS/Nest/Mongo/Redis/BullMQ/FCM/Stripe/OpenAI/Render). Manual additions between markers are preserved.

## Post-Design Constitution Re-Check

No ratified constitution → no new violations introduced. **Gate: PASS.**

## Open Questions Carried Forward

These were surfaced by the second clarification round but not answered before the user advanced to `/speckit.plan`. They are pinned with research-phase defaults in `research.md`; if the team disagrees with any default, re-run `/speckit.clarify` to lock them into the spec before `/speckit.tasks`:

| # | Question | Default applied |
|---|---|---|
| OQ-1 | What is an unverified user allowed to do? | Soft gate (RD-1): full access; verification required only for password change, email change, subscription purchase. |
| OQ-2 | When does the system auto-abort an orphaned pomodoro? | After 4 h continuous in `status = active` (RD-2). |
| OQ-3 | Does a 5-minute "completed cycle" count for streak? | No (RD-3): the cycle's configured `focusMinutes ≥ 10` is required for a session to qualify. |
| OQ-4 | What is the AI artifact retention policy? | Persist for the lifetime of the user account; retained on premium→free downgrade; deleted with the account on the 30-day purge (RD-4). |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| — | No constitution to violate | n/a |
