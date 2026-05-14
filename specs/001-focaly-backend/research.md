# Phase 0 Research: Focaly Backend

**Feature**: 001-focaly-backend
**Date**: 2026-05-14
**Status**: Complete (no unresolved blockers; defaults applied to four open questions carried forward from Round 2 of `/speckit.clarify`)

Each row records: the decision, the rationale, and the alternatives considered and why rejected. Decisions that simply re-affirm `docs/architecture.md` are marked **(AR-N)** with a pointer to the architecture-doc section; decisions that resolve a spec-level open question are marked **(RD-N)**.

---

## Spec-level open questions (defaults applied)

### RD-1 — Email verification gating behavior

**Decision**: Soft gate. A registered but unverified user MAY use the entire app (read and write their own resources) immediately after registration. Verification is REQUIRED before any of the following actions:

1. Changing the account password (POST `/auth/change-password` — separate from forgot-password flow).
2. Changing the account email address.
3. Initiating a paid subscription purchase (Stripe checkout, IAP receipt registration).

Until verified, the API returns `{ code: "EMAIL_VERIFICATION_REQUIRED" }` (403) on those three endpoints only. All other endpoints behave normally. The mobile client receives an `emailVerified: false` flag in `GET /users/me` so it can render a dismissible banner.

**Rationale**: Standard consumer-mobile pattern (Spotify, Duolingo, most habit apps). Maximizes onboarding conversion by removing the verify-before-use friction step, while still blocking the abuse vectors that actually matter (account takeover via password reset, identity confusion, and chargeback exposure from unverified payment accounts). Aligns with spec SC-001's 3-minute time-to-workspace target — a hard verification block would routinely break that.

**Alternatives considered**:
- **Hard block at sign-in until verified** — Rejected: breaks SC-001 every time the user doesn't immediately check email; kills conversion.
- **Time-boxed grace (7 days then read-only)** — Rejected: adds state-machine complexity for negligible abuse benefit over the soft gate.
- **No enforcement** — Rejected: leaves the chargeback / impersonation vector open at the subscription step.

**Implication for FR**: This refines FR-002 but does not contradict it. If the user disagrees, re-run `/speckit.clarify` to overwrite.

---

### RD-2 — Pomodoro orphan timeout

**Decision**: A pomodoro session in `status = active` that has not been updated (paused, completed, or aborted) for more than 4 hours is automatically aborted by a maintenance worker. The session is moved to `status = aborted` with `endedAt = startedAt + 4h` and `totalFocusMinutes` is computed as `min(actualElapsed, 4h × focusMinutes/(focusMinutes+breakMinutes))`. The user receives a `system` push when their session is auto-aborted so they understand why "today's focus minutes" did not include it.

**Rationale**: A genuine single-sitting study session rarely exceeds 4 hours; longer "active" durations almost always mean the app was killed or the device went offline. A 4 h cap caps the maximum overcount of "today's focus minutes" before truncation kicks in. Computing `totalFocusMinutes` via the configured focus/break ratio (rather than full elapsed time) prevents auto-aborted sessions from inflating analytics and streak math — coupled with **RD-3**, this means a forgotten session cannot earn a streak day on its own.

**Implementation**: A maintenance cron `*/15 * * * *` scans for `status = active && updatedAt < now - 4h` and calls the same `abort()` use case the user would call manually.

**Alternatives considered**:
- **1-hour timeout** — Rejected: a genuine "deep work" session up to 2–3 hours is common and we'd auto-abort real sessions.
- **No timeout** — Rejected: "today's focus minutes" can grow unboundedly for forgotten sessions.
- **Treat as completed instead of aborted** — Rejected: that would advance the streak for a session the user didn't actually finish.

**Implication for FR**: New edge-case behavior derived from the existing edge-case bullet in the spec; does not require a new FR. The maintenance cron is folded into the cron table already documented in `docs/architecture.md` §6.4.

---

### RD-3 — Minimum focus duration for streak qualification

**Decision**: A pomodoro session qualifies as a "qualifying study activity" (FR-020) only if **all** of the following hold:

1. `status = completed`.
2. `completedCycles ≥ 1`.
3. The session's configured `focusMinutes ≥ 10` (i.e., a "completed cycle" is only streak-relevant if its configured focus duration was at least 10 minutes).

A user who configures a 5-minute focus session and "completes" it does NOT earn a streak day from it.

**Rationale**: Prevents trivial gameability of the streak (which is the product's primary retention mechanism). 10 minutes is a defensible floor: it's longer than the well-known 5-minute productivity-tip threshold, shorter than the 25-minute "real pomodoro," and lines up with how most habit apps define "you studied today." The configured-duration check (rather than actual elapsed time) is necessary because the user could otherwise start a long-duration session and complete it instantly.

**Alternatives considered**:
- **No minimum (any completed cycle counts)** — Rejected: a 1-minute session × 1 cycle becomes a streak day, which the product's incentive design cannot survive.
- **`focusMinutes ≥ 15`** — Rejected: 15 is a common minimum but the default pomodoro is 25 / 5; setting the floor at 10 still allows the legitimate "I only had 15 minutes today" case.
- **Actual elapsed `≥ 10 min`** — Rejected: more accurate but harder to enforce given pause/resume; the configured-duration check is robust against gaming because the user chooses the duration up-front.

**Implication for FR**: Tightens FR-020 by adding the `focusMinutes ≥ 10` constraint. Implementation will fold this into the streaks event handler.

---

### RD-4 — AI artifact retention policy

**Decision**: AI artifacts (summary, flashcard deck, important-questions list) are retained for the lifetime of the user account. They are NOT deleted when a premium user downgrades to free — the user paid for those artifacts and keeps them as read-only history. They are deleted as part of the standard account-deletion purge (within 30 days of soft-delete, per spec FR-009 / SC-012).

A downgraded user can read existing artifacts and delete them on demand. They cannot generate new AI jobs until they re-upgrade (FR-035 + FR-036 already enforce this).

**Rationale**: Matches consumer expectations for paid content: "if I paid for it once, I shouldn't lose it because I let my subscription lapse." This also avoids a backup-style "before downgrade, export your AI notes" UX flow that would significantly increase support burden.

**Alternatives considered**:
- **Delete artifacts on downgrade** — Rejected: poor UX; would surface as user-visible data loss; high support-ticket cost.
- **Retain for N days after downgrade, then purge** — Rejected: adds a separate retention timer for one type of object; complexity not justified.
- **Tie to the originating subject's lifecycle (delete with subject)** — Adopted as a secondary rule: deleting the subject also deletes its AI artifacts (since they reference the subject); this is independent of plan transitions.

**Implication for FR**: Adds an implicit FR around AI artifact lifecycle that the data model and Subject-deletion handler must implement. No FR rewrite needed; this is a Phase-0 decision the implementation will follow.

---

## Architecture-level decisions (re-affirmed from `docs/architecture.md`)

### AR-1 — Modular monolith over microservices for MVP

**Decision**: Single deployable Nest application; module boundaries enforced via folder layout and CQRS events. Carve-out workers (`notifications-worker`, `ai-worker`, `analytics-worker`) when load demands.

**Rationale (architecture §1.1)**: Small team; feature coupling (subject ↔ schedule ↔ streak) shares models; one deployable is the right blast radius for MVP; module borders make future split cheap.

**Alternatives considered & rejected**: Microservices (network chatter + deployment cost); single-service with no module borders (slows future split).

---

### AR-2 — MongoDB + Mongoose as primary store

**Decision**: One Atlas cluster; collections per `docs/architecture.md` §2.1; compound indexes on `userId + <sort/filter>`; TTL indexes on inbox/audit/auth_sessions.

**Rationale**: Per-user document patterns (subjects, planned items, sessions) fit naturally; PlannedItem discriminator collapses 4 user-facing types into one collection; aggregation pipelines deliver analytics without a separate warehouse.

**Alternatives considered & rejected**: Postgres + JSONB (excellent option, but Mongoose's developer ergonomics and the team's familiarity with Mongo from architecture doc tip the balance); DynamoDB (cost & query-flexibility tradeoffs unattractive at MVP scale).

---

### AR-3 — Redis for cache, throttler, and BullMQ broker

**Decision**: One Upstash Redis instance shared across `@nestjs/throttler` (sliding-window rate limits), the AI per-user limiter (FR-039), Nest cache interceptor for hot reads (e.g., `/users/me`, subjects list), and BullMQ broker.

**Rationale**: Single managed dependency; the patterns (sliding-window, distributed cache, queue) all map to Redis primitives.

**Alternatives considered & rejected**: Separate Redis instances per concern (operational overhead, no isolation benefit at MVP); in-memory throttler (breaks horizontal scaling — explicit anti-pattern in `docs/architecture.md` §11).

---

### AR-4 — BullMQ for async work (not SQS / Lambda)

**Decision**: Five queues — `notifications`, `ai`, `analytics`, `subscription`, `maintenance` — with concurrencies per `docs/architecture.md` §6.3 and a Bull-Board admin surface for ops.

**Rationale**: We already need Redis; BullMQ removes an external dependency (no SQS account / IAM); delayed jobs map directly to the reminder scheduler (FR-025/26).

**Alternatives considered & rejected**: SQS + Lambda (adds AWS dependency at MVP; harder local-dev story); cron-only without queues (no fan-out, no retries, no concurrency control).

---

### AR-5 — JWT design: RS256, short-lived access + rotating long-lived refresh

**Decision**: RS256-signed JWTs. Access credential 15 min (per spec FR-005), refresh credential 30 days, rotating, with theft-detection via family revocation on reuse (FR-007). Key pair stored in env, rotated quarterly.

**Rationale**: Public-key verification means worker processes and future carve-outs can verify tokens without holding the signing key. 15/30 + rotation is the industry-standard mobile pattern; reuse detection is the OWASP-recommended way to defang stolen refresh credentials.

**Alternatives considered & rejected**: HS256 (worker processes would need the signing secret); opaque session tokens looked up in Redis (more DB hops per request — would impact SC-002).

---

### AR-6 — Push notifications via Firebase Cloud Messaging

**Decision**: FCM as the single push provider. Per-device tokens stored on `auth_sessions` (one token per session, fans out via multicast for users with multiple devices). Invalid-token responses from FCM clear the stored token (FR-031).

**Rationale**: FCM speaks to both Android and iOS (via APNs bridge), so we ship one integration. Architecture §6 already specifies this.

**Alternatives considered & rejected**: Direct APNs + direct FCM (two integrations for marginal latency improvement); a managed provider like OneSignal (extra cost layer + vendor lock).

---

### AR-7 — Reminder scheduling: Mongo as source of truth, BullMQ as dispatcher

**Decision**: Every scheduled reminder is persisted as a `notification_jobs` row with its `scheduledAt`; a `*/5 * * * *` cron enqueues all rows whose `scheduledAt` falls in the next 10 minutes into the BullMQ `notifications` queue as a delayed job; the worker dispatches to FCM at fire time and writes the inbox entry on success.

**Rationale (architecture §6.2)**: Mongo survives Redis flush; supports timezone re-computation when a user changes TZ (spec edge case); makes "reschedule on edit / cancel on delete" (FR-027) a single Mongo write. BullMQ delayed jobs are the right primitive for sub-minute timing at the dispatch boundary.

**Alternatives considered & rejected**: BullMQ-only (loses durability across Redis flushes; harder to recompute on TZ changes); a separate scheduler service (overkill at MVP).

---

### AR-8 — OCR: AWS Textract (with Tesseract local-dev fallback)

**Decision (architecture §8.2)**: Textract for production handwriting + table extraction; Tesseract for local dev only. OCR results cached by image SHA-256 in Mongo (`ai_jobs.ocrCache` or a dedicated collection) to avoid re-billing on retries.

**Rationale**: Textract significantly outperforms Tesseract on handwritten notes (the dominant input). The cache by content hash addresses the cost-control concern from architecture §8.3.

**Alternatives considered & rejected**: Google Vision (comparable quality, but adds a second cloud SDK dependency when we're already on AWS for S3); on-device OCR (off-loads work but mobile-only and inconsistent).

---

### AR-9 — LLM strategy: `gpt-4o-mini` default, `gpt-4o` escalation, JSON-mode for structured outputs

**Decision (architecture §8.3 + §8.5)**: Three LLM calls per AI job (summary → flashcards → questions), all using the OpenAI Responses API with prompt caching for the shared system prompt. Default `gpt-4o-mini`; escalate to `gpt-4o` only when confidence < 0.6. Flashcards and questions are returned in strict JSON-mode and validated with Zod before persisting.

**Rationale**: Cost-optimal for the per-user rate limit pinned at 5/hour 30/month (FR-039); JSON-mode + Zod prevents downstream consumers from breaking on malformed model output.

**Alternatives considered & rejected**: A single multi-task prompt (worse output quality, harder to debug); `gpt-4o` for everything (cost prohibitive at the AI rate limit); free-form output with regex parsing (fragile).

---

### AR-10 — Three billing providers converging into one `subscriptions` record

**Decision (architecture §7.3)**: `subscriptions` is the single source of truth across Stripe / Google Play / App Store. Per-user uniqueness; `(provider, providerSubId)` uniqueness for cross-provider lookups; provider event idempotency via `payment_events.(provider, eventId)` unique index (FR-034). `User.plan` / `User.premiumUntil` are mirrored for fast per-request `PremiumGuard` checks (FR-035).

**Rationale**: One code path for premium gating regardless of how the user paid; replays from any provider are no-ops; mirror columns avoid an extra join on every authenticated request.

**Alternatives considered & rejected**: Three separate plan records (gating logic forks per provider); no mirror columns (every authenticated request joins to `subscriptions`).

---

### AR-11 — No Docker, deploy to Render Node runtime

**Decision (architecture §12)**: Render Web Service (Node runtime, `node dist/main.js`) + Render Background Worker (`node dist/worker.js`). Same source, two entry points. AWS Elastic Beanstalk Node platform as the scale-up path. **No Dockerfile** at any tier.

**Rationale**: User-stated hard constraint. Render's native Node build is faster to iterate against than a container image and there's no operational gap for our footprint.

**Alternatives considered & rejected**: Docker on Render or ECS (forbidden by constraint); plain VPS with PM2 (loses managed-platform observability and rolling deploys).

---

### AR-12 — Swagger UI as the primary manual-testing surface

**Decision (architecture §14)**: Every endpoint must be exercisable end-to-end from `/docs` with `persistAuthorization: true`. Disabled in production by default; protected by basic auth on staging. CI exports `docs/openapi.json` and Spectral-lints it.

**Rationale**: Eliminates a separate Postman-collection-maintenance step; the schema is the contract; the mobile client can codegen from it.

**Alternatives considered & rejected**: Postman + maintained collection (drifts from reality); pure code-tests-only (loses the manual exploration surface QA needs).

---

## Summary

All NEEDS-CLARIFICATION items from the plan's Technical Context are resolved. The four open questions from the second `/speckit.clarify` round have explicit Phase-0 defaults (RD-1 through RD-4) and are flagged in `plan.md`'s "Open Questions Carried Forward" table. Re-run `/speckit.clarify` to overwrite any default in the spec before `/speckit.tasks` if the team disagrees.

Phase 1 can proceed (data-model.md, contracts/openapi.yaml, quickstart.md).
