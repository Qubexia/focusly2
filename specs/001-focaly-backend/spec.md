# Feature Specification: Focaly Backend — Study Management Platform

**Feature Branch**: `001-focaly-backend`
**Created**: 2026-05-14
**Status**: Draft
**Input**: User description: "Specify the plan in the docs folder" (source: `docs/architecture.md` — Focaly Study Management Mobile App backend)

## Overview

Focaly is a study management product whose mobile client lets students organize subjects, build study schedules, run pomodoro sessions, maintain daily streaks, plan lectures/revisions/exams, manage tasks, and (on a premium plan) unlock advanced analytics, focus mode, an AI notes assistant, and unlimited subjects. This specification describes the **backend platform** that powers that mobile experience — what it must do for users and the business, not how it is built.

## Clarifications

### Session 2026-05-14

- Q: What counts as a "qualifying study activity" for streaks? → A: Only a completed pomodoro session with at least one full focus cycle.
- Q: AI per-user rate limits? → A: 5 jobs per rolling hour and 30 jobs per calendar month, per user.
- Q: Session lifetime / re-auth cadence? → A: 15-minute short-lived access credential + 30-day rotating long-lived credential.
- Q: Focus Mode — which push categories are "critical" and bypass suppression? → A: None — Focus Mode suppresses every push category during an active focus session; messages queue as inbox entries and surface on session end.
- Q: Monthly availability SLO target? → A: 99.5% monthly (≈3.6 hours of allowed downtime per calendar month), measured on the public API.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign up, sign in, and access the study workspace (Priority: P1)

A new student installs the mobile app, creates an account (or signs in with Google), verifies their email, and gets a secure, persistent session on their device so the app can read and write their study data going forward. Returning users sign in on any device and stay signed in across days without re-entering credentials, while still being able to see and revoke other active devices.

**Why this priority**: Without authenticated, multi-device access the rest of the product cannot be used at all. This is the foundational habit loop entry point.

**Independent Test**: Can be fully tested by completing the register → verify → login → "see my profile" → list/revoke active devices → logout flow from the mobile client (or documentation UI) and confirming sessions survive app restarts and that revoking a device immediately blocks it.

**Acceptance Scenarios**:

1. **Given** a visitor with a valid email, **When** they submit registration with a password, **Then** an account is created, a verification email is sent, and they receive a session that allows access to their own data only.
2. **Given** a user with verified credentials on a new device, **When** they sign in (email/password or Google), **Then** the device appears in their active-devices list and stays signed in across app restarts for the configured session lifetime.
3. **Given** a signed-in user, **When** they choose "Sign out of all devices", **Then** every previously active device must re-authenticate on its next action.
4. **Given** a user who forgot their password, **When** they request a reset and follow the email link, **Then** they can set a new password and previous sessions are revoked.

---

### User Story 2 - Organize subjects and chapters within plan limits (Priority: P1)

A student creates the subjects they are studying (e.g., "Organic Chemistry"), customizes each with a color/icon and a daily study target, and breaks each subject into chapters they can tick off. Free users are limited to a small number of active subjects so the product can clearly demonstrate premium value; premium users have no limit.

**Why this priority**: Subjects are the organizing entity for every other study activity (schedules, pomodoro, tasks, analytics). Nothing else is meaningful until a user has at least one subject.

**Independent Test**: A free user can create up to the free-tier subject cap, sees a clear blocking error when attempting one more, can archive a subject to free a slot, and can mark chapter completion which updates the subject's progress percentage.

**Acceptance Scenarios**:

1. **Given** a free user with no subjects, **When** they create subjects one by one, **Then** the first three succeed and the fourth is rejected with a clearly labeled "subject limit reached" message that suggests upgrading.
2. **Given** a free user at the limit, **When** they archive one subject, **Then** they can immediately create a new active subject.
3. **Given** a user with a subject containing chapters, **When** they mark a chapter complete, **Then** the subject's progress percentage reflects the new ratio of completed chapters.
4. **Given** a premium user, **When** they create subjects, **Then** there is no upper limit enforced.

---

### User Story 3 - Plan study time and complete pomodoro sessions (Priority: P1)

A student creates a recurring weekly study schedule for a subject and runs pomodoro sessions (focus + short break cycles) against it. The backend records every completed session so the user can see "today's focus minutes" and history, and these completions feed downstream features (streaks, analytics, rewards).

**Why this priority**: Pomodoro plus scheduled study is the core daily habit the product exists to support — it is what users come back for every day.

**Independent Test**: A user creates a schedule for a subject, starts a pomodoro for that subject, pauses, resumes, completes it with N cycles, and then sees "today's focus minutes" reflect that session and the session in their history.

**Acceptance Scenarios**:

1. **Given** a user with a subject, **When** they create a weekly schedule with specific days and a start time, **Then** the schedule is saved and visible in their week/calendar view.
2. **Given** a user with no active session, **When** they start a pomodoro (optionally tied to a subject), **Then** a session is recorded as active.
3. **Given** an active pomodoro, **When** the user pauses and later resumes, **Then** elapsed focus time is preserved and the session remains in progress.
4. **Given** an active pomodoro, **When** the user completes it with a given number of cycles, **Then** the session is marked completed, total focus minutes are stored, and "today's focus minutes" increases by that amount.
5. **Given** a user with prior completed sessions, **When** they request session history within a date range, **Then** they receive paginated results.

---

### User Story 4 - Maintain a daily study streak with rewards (Priority: P2)

A student who studies on consecutive calendar days (in their own timezone) builds up a streak. The system tracks current and longest streaks, awards points and reward badges at milestones (e.g., 3, 7, 30, 100 days), and notifies users when they earn one. Missing a day breaks the streak.

**Why this priority**: Streaks are the primary retention mechanism. They are not required for first use but materially drive return visits.

**Independent Test**: A user completes a study activity today, then again "tomorrow" (using the system's local-day math) — current streak becomes 2; skipping a day resets current to 0 while longest is preserved. Crossing a reward threshold creates a reward entry and a notification.

**Acceptance Scenarios**:

1. **Given** a user with no prior activity, **When** they complete their first qualifying study activity today (a pomodoro session with `status = completed` and `completedCycles ≥ 1`), **Then** current streak becomes 1 and longest is at least 1.
2. **Given** a user with current streak N whose last active day was yesterday (in their timezone), **When** they complete a qualifying activity today, **Then** current becomes N+1.
3. **Given** a user with current streak N whose last active day was more than one day ago, **When** the daily streak-maintenance check runs, **Then** current resets to 0 and longest is unchanged.
4. **Given** a user whose current streak crosses a configured threshold, **When** the threshold is reached, **Then** the user receives reward points, a reward entry is added to their record, and a notification is delivered.

---

### User Story 5 - Plan tasks, revisions, lectures, and exams with reminders (Priority: P2)

A student plans dated items in four categories — tasks (general to-dos), revisions, lectures (class times), and exams (test dates) — each optionally tied to a subject, optionally recurring (daily/weekly/once), and each with a configurable "remind me N minutes before" offset. Reminders are delivered as push notifications and recorded in an in-app inbox.

**Why this priority**: Planning and reminders convert intent into action and are central to the product's promise. They depend on auth and subjects but are independent of pomodoro/streaks.

**Independent Test**: A user creates an exam dated tomorrow with a 60-minute reminder offset — at the right moment the user receives a push notification and an inbox entry; the user can mark the item complete and see it removed from upcoming items.

**Acceptance Scenarios**:

1. **Given** a user, **When** they create a task / revision / lecture / exam with a date and optional subject, **Then** it appears in the listing for that category, filterable by date range and subject.
2. **Given** a planned item with reminders enabled and an offset, **When** the offset time before the planned moment is reached, **Then** a push notification is delivered to the user's active devices and an inbox entry is created.
3. **Given** a planned item, **When** the user marks it complete, **Then** completion is recorded and reward points are added where applicable; the user's streak is NOT advanced by this action (streaks advance only on completed pomodoro sessions — see FR-020).
4. **Given** a user editing or deleting an item that already has a scheduled reminder, **When** they save the change, **Then** previously scheduled reminders for that item no longer fire and the new reminder (if any) is scheduled.

---

### User Story 6 - Receive timely, preference-respecting notifications (Priority: P2)

Users see scheduled reminders and other system events (streak milestones, reward unlocks) in two places: as push notifications on their device and as entries in an in-app inbox they can mark read or clear. Users can toggle categories of notifications (reminders, streak, marketing) and enable a focus mode that suppresses non-critical pushes during active study sessions.

**Why this priority**: Notifications convert plans into action and protect retention; preference controls protect trust.

**Independent Test**: Toggle off the "reminders" category and confirm that a newly scheduled reminder no longer creates a push but its inbox row still appears for audit; enable focus mode, start a pomodoro, and confirm non-critical pushes are suppressed until the session ends.

**Acceptance Scenarios**:

1. **Given** a user with the reminders category enabled, **When** a scheduled reminder fires, **Then** they receive a push and a new inbox entry.
2. **Given** a user with the reminders category disabled, **When** a scheduled reminder fires, **Then** no push is sent (an inbox entry may still be recorded for audit; this is acceptable as long as the device is not disturbed).
3. **Given** a user with Focus Mode enabled and an active pomodoro session, **When** any push would fire, **Then** it is suppressed (no device push delivered) for every category; an inbox entry is still recorded and surfaces when the user opens the app, and normal push delivery resumes once the session ends.
4. **Given** a user with inbox entries, **When** they mark one read, mark all read, or delete one, **Then** the inbox state reflects the change immediately.
5. **Given** a user who deletes their account, **When** the retention period elapses, **Then** old inbox entries are purged automatically.

---

### User Story 7 - Upgrade to premium and unlock gated features (Priority: P2)

A user upgrades to premium through the appropriate billing channel for their platform (web/Stripe, Google Play, App Store). Upon successful payment confirmation, premium-only features (unlimited subjects, full analytics date ranges, focus mode, AI notes assistant, ad-free) become available immediately. When a subscription lapses, cancels, or fails, the user is downgraded and gated features are denied with a clear "premium required" message.

**Why this priority**: Premium is the business model. It is not required for an MVP user to derive value, but it is required for the product to be a viable product.

**Independent Test**: A free user attempts a premium-only action and is denied with a clear premium-required message; after completing a sandbox purchase on each supported channel, the same action succeeds; upon a simulated cancellation/expiry webhook the action is denied again.

**Acceptance Scenarios**:

1. **Given** a free user, **When** they request a premium-only resource (e.g., a date-range analytics summary), **Then** the request is rejected with a clearly labeled "premium required" response.
2. **Given** a user who has just completed a purchase, **When** the billing provider confirms the purchase, **Then** the user's plan is updated to premium within seconds and they can immediately access gated features.
3. **Given** a premium user whose subscription is canceled or expires, **When** the provider notifies the system, **Then** the user is downgraded and premium-only features are denied on the next access.
4. **Given** a billing provider that re-delivers the same payment event, **When** the system processes it, **Then** the second delivery has no additional effect on the user's plan or billing state.

---

### User Story 8 - Get AI-generated study materials from lecture images (Priority: P3)

A premium student uploads photos of handwritten or printed lecture notes. The system asynchronously extracts the text, then produces three artifacts the student can use to study: a concise summary, a deck of flashcards (Q/A), and a list of likely important questions. The student can poll the job until it completes and then browse the artifacts in-app.

**Why this priority**: This is a premium upsell differentiator, not a day-one essential. It depends on uploads, subscription, and notifications.

**Independent Test**: A premium user requests a presigned upload, uploads images, submits an AI job, polls until status is `completed`, and receives a summary plus a flashcard deck plus a list of questions for the right subject.

**Acceptance Scenarios**:

1. **Given** a premium user with uploaded lecture images, **When** they submit an AI notes job, **Then** the system returns a job identifier and the job begins processing in the background.
2. **Given** an in-progress job, **When** the user polls it, **Then** they see a current status (`queued`, `processing`, `completed`, or `failed`) and, on completion, a list of generated artifacts (summary, flashcards, questions).
3. **Given** a user who has reached the per-user AI rate limit, **When** they submit another job, **Then** the request is rejected with a clear rate-limit message indicating when they can retry.
4. **Given** a free user, **When** they attempt to submit an AI job, **Then** the request is rejected with a premium-required message.

---

### User Story 9 - See progress through analytics (Priority: P3)

A student opens analytics to see how much they have studied — totals, breakdown by subject, a year-long heatmap of daily minutes, and completion rates over a chosen date range. Free users see only the current week; premium users can pick any date range and see all charts.

**Why this priority**: Reinforces the habit loop and supports the premium pitch, but the product is usable without it on day one.

**Independent Test**: A premium user with prior pomodoro and task activity requests a summary and per-subject breakdown for the last 30 days and a heatmap for the year; numbers reconcile with raw session history; a free user requesting any range beyond "this week" is denied.

**Acceptance Scenarios**:

1. **Given** a premium user with study history, **When** they request an analytics summary for a date range, **Then** they receive totals (focus minutes, sessions, tasks completed) and a per-subject breakdown for that range.
2. **Given** a premium user, **When** they request a heatmap for a calendar year, **Then** they receive one entry per day with the focus minutes for that day.
3. **Given** a free user, **When** they request the current week summary, **Then** they receive it; requesting a wider range is denied with a premium-required message.
4. **Given** a user with no study activity in a range, **When** they request the summary, **Then** the response is a well-formed empty result, not an error.

---

### Edge Cases

- A user travels across timezones during an active streak — streak math must continue to use the user's chosen timezone (their stored timezone setting), not server time, so streaks do not break or jump because of travel.
- A user's device clock is wrong — the system must rely on server-side timing for reminders and streak boundaries.
- A billing webhook arrives out of order (cancellation arrives before activation) — the most recent provider-asserted state for that subscription must win.
- A scheduled reminder's underlying item (task/exam/schedule) is deleted before the reminder fires — the pending reminder must be cancelled and must not be delivered.
- A user changes the reminder offset of an item that already has a pending reminder — the old reminder is cancelled and a new one scheduled.
- A user changes their timezone — pending reminders' fire times are recomputed where appropriate so they still land at the right local moment.
- A pomodoro is left active for an unreasonable duration (e.g., the user closed the app) — the system must be able to abort or auto-complete orphaned sessions instead of letting them inflate "today's focus minutes" forever.
- Email verification links and password reset links must be single-use and time-limited; replay attempts must be denied.
- A long-lived session credential is presented twice (a clear theft signal) — every credential issued to that session family must be revoked and the user forced to sign in again.
- A free user is exactly at the subject limit and tries to un-archive an already-archived subject — un-archiving must be treated like a new creation against the limit.
- A user requests a date range larger than the data set or in the future — responses are well-formed empty results, not errors.
- Push notifications fail to deliver to a device (token invalid/expired) — the device's stored push token is cleared so the system stops attempting it.
- AI job inputs fail OCR or the model returns malformed structured output — the job is marked failed with a user-readable reason; the user is not silently left waiting.
- A user deletes their account — their data must enter a deletion pipeline and be removed within a defined retention window; in the meantime they cannot sign in.

## Requirements *(mandatory)*

### Functional Requirements

#### Identity & Access

- **FR-001**: The system MUST allow a visitor to create an account using either email + password or a verified Google identity, and MUST treat the email address as the unique user identifier across sign-in methods.
- **FR-002**: The system MUST send an email verification message on registration and MUST allow a user to confirm their email via a single-use, time-limited link.
- **FR-003**: The system MUST allow a user to sign in from multiple devices and MUST track each device session independently, including the device-specific push notification token.
- **FR-004**: The system MUST allow a user to view all of their active device sessions and to revoke any specific session or all sessions.
- **FR-005**: The system MUST issue each authenticated session as a pair of credentials: a **short-lived access credential valid for 15 minutes** (used to authorize every request) and a **long-lived refresh credential valid for 30 days from issue, rotated on every refresh** (used silently by the client to obtain a new access credential). The client MUST be able to refresh without user interaction as long as the long-lived credential is unexpired and unrevoked; once the long-lived credential expires or is revoked, the user MUST re-authenticate.
- **FR-006**: The system MUST allow a user to request a password reset by email and MUST allow them to set a new password via a single-use, time-limited link, after which existing sessions are revoked.
- **FR-007**: The system MUST detect reuse of a previously consumed long-lived session credential (a clear theft signal) and MUST revoke the entire session family and require re-authentication.

#### User Profile & Settings

- **FR-008**: The system MUST allow a signed-in user to read and update their own profile (name, locale, timezone, avatar) and notification preferences.
- **FR-009**: The system MUST allow a user to soft-delete their account and MUST permanently remove their personal data within a documented retention window after deletion.
- **FR-010**: The system MUST allow a user to register/update the push notification token associated with their current device.

#### Subjects & Chapters

- **FR-011**: The system MUST allow a user to create, list, view, edit, and archive subjects scoped to themselves; subjects MUST never be visible to other users.
- **FR-012**: The system MUST enforce a maximum of 3 active (non-archived) subjects per user on the free plan, MUST allow unlimited active subjects on the premium plan, and MUST reject over-limit creation attempts with a clear, machine-distinguishable "subject limit reached" error.
- **FR-013**: The system MUST allow a user to create and manage chapters within a subject and MUST keep a subject's progress percentage in sync with the ratio of completed chapters.

#### Study Schedules

- **FR-014**: The system MUST allow a user to create recurring weekly study schedules tied to a subject, with a start date/time, an end date (optional), specific days of the week, and a reminder offset.
- **FR-015**: The system MUST allow a user to retrieve their schedule for a calendar range (e.g., week view) and to edit or delete individual schedules.

#### Pomodoro Sessions

- **FR-016**: The system MUST allow a user to start, pause, resume, complete, and abort a pomodoro session, optionally tied to a subject.
- **FR-017**: The system MUST persist each session's start time, end time, configured focus/break durations, completed cycles, total focus minutes, and final status.
- **FR-018**: The system MUST provide a user's "today" total focus minutes and a paginated history within a date range.

#### Streaks & Rewards

- **FR-019**: The system MUST maintain, per user, a current streak count, a longest-ever streak, total reward points, and a list of unlocked reward badges.
- **FR-020**: The system MUST compute streak day boundaries in the user's own timezone, MUST increment the current streak when a qualifying activity occurs on the calendar day immediately following the last active day, MUST keep the current streak unchanged when an additional qualifying activity occurs on the same day, and MUST reset the current streak to zero when the user has no qualifying activity for more than one calendar day. A **qualifying study activity** is defined as a pomodoro session reaching `status = completed` with at least one full focus cycle (`completedCycles ≥ 1`). Completion of planned items (tasks, revisions, lectures, exams) is NOT a qualifying study activity and MUST NOT advance the streak.
- **FR-021**: The system MUST award reward points and an unlocked reward entry when the current streak first reaches each configured milestone (3, 7, 30, 100 days) and MUST notify the user.

#### Planned Items (Tasks / Revisions / Lectures / Exams)

- **FR-022**: The system MUST allow a user to create, list (filtered by date range and subject), view, edit, complete, and delete items in each of four categories: tasks, revisions, lectures, exams.
- **FR-023**: The system MUST allow each planned item to be optionally tied to a subject, optionally recurring (daily/weekly/once), and to carry a reminder offset and reminder-enabled flag.
- **FR-024**: The system MUST award configured reward points when a planned item is marked complete. Planned-item completion MUST NOT advance the user's streak (see FR-020 for the streak definition).

#### Notifications (Inbox + Push)

- **FR-025**: The system MUST schedule a reminder for every planned item and study schedule that has reminders enabled, computed as the planned moment minus the configured offset, in the user's timezone.
- **FR-026**: The system MUST deliver scheduled reminders as push notifications to the user's active devices at the scheduled time and MUST record a corresponding inbox entry.
- **FR-027**: The system MUST cancel pending reminders when their underlying item is deleted, when reminders are disabled on the item, or when the scheduled time changes (a new reminder is scheduled in its place).
- **FR-028**: The system MUST allow a user to read, mark read, mark-all-read, and delete inbox entries, and MUST automatically purge inbox entries older than 90 days.
- **FR-029**: The system MUST honor the user's per-category notification preferences (reminders, streak, marketing) before sending a push.
- **FR-030**: While the user has Focus Mode enabled AND a pomodoro session in `status = active`, the system MUST suppress **all** push notification categories (reminder, streak, reward, system, marketing). Suppressed messages MUST still be recorded as inbox entries so the user sees them when they open the app. When the focus session ends (`completed`, `aborted`, or transitions out of `active`), or when Focus Mode is disabled, push delivery resumes normally for subsequent events. No category is privileged with a Focus-Mode bypass.
- **FR-031**: The system MUST retry transient push delivery failures with backoff and MUST clear stored push tokens that the provider reports as permanently invalid.

#### Subscriptions & Premium Gating

- **FR-032**: The system MUST support paid premium subscriptions purchased through Stripe (web), Google Play Billing (Android), and the App Store (iOS), and MUST converge all three into a single per-user subscription record.
- **FR-033**: The system MUST update a user's plan to premium upon receipt of a confirmed activation event from any supported provider, and MUST downgrade a user upon receipt of a confirmed cancellation, expiration, or non-recoverable payment failure.
- **FR-034**: The system MUST treat duplicate provider event deliveries as no-ops (idempotent by provider event identifier) and MUST log every payment-related event for audit.
- **FR-035**: The system MUST always derive a user's effective plan on the server (never trust a client claim) and MUST deny premium-only requests from non-premium users with a clear, machine-distinguishable "premium required" error.

#### AI Notes Assistant (Premium)

- **FR-036**: The system MUST allow a premium user to upload lecture images via a secure, server-issued upload mechanism and to submit an AI notes job referencing the uploaded images.
- **FR-037**: The system MUST process AI notes jobs asynchronously and MUST produce, for each job, a summary, a flashcard deck (Q/A pairs), and a list of likely important questions, persisted as retrievable artifacts.
- **FR-038**: The system MUST allow a user to poll an AI job's status and to retrieve its artifacts once completed, and MUST notify the user when a job completes.
- **FR-039**: The system MUST enforce per-user rate limits on AI jobs of **5 jobs per rolling 1-hour window** and **30 jobs per calendar month** (month measured in UTC), and MUST reject over-limit requests with a clear rate-limit message that distinguishes hourly vs. monthly exhaustion and includes retry-after information (seconds until the hourly window slides, or until the start of the next calendar month).
- **FR-040**: The system MUST mark AI jobs `failed` with a user-readable reason when the input cannot be processed or the generated structured output is invalid, and MUST surface this status to the user.

#### Analytics

- **FR-041**: The system MUST provide an analytics summary (total focus minutes, sessions, tasks completed) for a date range, a per-subject breakdown for a date range, a year-long daily heatmap of focus minutes, and a completion/retention performance view.
- **FR-042**: The system MUST restrict free users to the current week only and MUST allow premium users to request any date range; over-scope requests by free users MUST be denied with a clear "premium required" error.
- **FR-043**: Analytics MUST reconcile with the underlying activity (i.e., summing the source records over the same range yields the same totals).

#### Uploads

- **FR-044**: The system MUST issue short-lived, single-use, server-signed upload authorizations bound to a specific file type, size limit, and intended use (e.g., avatar, lecture image), and MUST never accept arbitrary client-asserted file metadata as authoritative.
- **FR-045**: The system MUST allow the client to confirm a completed upload so the resulting object can be linked to the relevant resource (e.g., user avatar, AI job input).

#### Platform & Cross-Cutting

- **FR-046**: All authenticated endpoints MUST enforce ownership: a user can read and modify only their own resources.
- **FR-047**: The system MUST validate all inputs and MUST return a single, consistently shaped error envelope for every error response, with a stable machine-readable code, a human-readable message, and optional details.
- **FR-048**: The system MUST apply rate limits to public and abuse-prone endpoints (notably authentication and AI endpoints) and MUST return a clear rate-limit message with retry-after information when exceeded.
- **FR-049**: The system MUST keep an audit log of security-relevant events (authentication events, plan changes, administrative actions) with a 1-year retention.
- **FR-050**: The system MUST expose a health endpoint reporting the liveness of the API and the readiness of its critical dependencies (database, cache/queue, push provider).
- **FR-051**: The system MUST be observable: every request is correlatable by a request identifier, errors are reported to an error tracker, and queue/job health is visible to operators.
- **FR-052**: The system MUST be fully API-documented and the documentation MUST be exercisable end-to-end (any endpoint can be invoked from the documentation surface with bearer-token auth that persists across reloads).

### Key Entities *(include if feature involves data)*

- **User** — A person using the product. Holds identity (email, optional Google identity), display profile (name, avatar, locale, timezone), plan state (`free` | `premium` with an expiry), settings (notifications, focus mode), engagement totals (points, last active), and a soft-delete flag.
- **Auth Session** — A signed-in device. One per (user, device). Holds the device's push token, the long-lived session credential (stored hashed), client metadata, and an expiry; can be revoked individually.
- **Subject** — A study area belonging to a user. Holds name, color, icon, daily target minutes, current progress, and an archived flag. Counted toward the free-plan subject limit only when not archived.
- **Chapter** — A unit of work within a Subject. Holds title, order, and completion state. Drives the parent Subject's progress percentage.
- **Study Schedule** — A recurring weekly intent to study a subject. Holds title, subject, start/end window, days-of-week, optional recurrence rule, reminder offset, and active flag.
- **Pomodoro Session** — A single focus session by a user, optionally tied to a subject. Holds start/end times, configured durations, completed cycles, total focus minutes, and final status (`active` | `paused` | `completed` | `aborted`).
- **Streak** — One record per user. Holds current streak, longest streak, last active local date, total reward points, and unlocked reward badges.
- **Planned Item** — A dated thing to do, in one of four kinds: `task`, `revision`, `lecture`, `exam`. Holds title, optional subject, planned time, optional duration, optional recurrence, reminder offset/enabled, completion state, and reward points.
- **Notification (Inbox Entry)** — A user-visible message stored for 90 days. Holds type (`reminder` | `streak` | `reward` | `system`), title, body, optional structured payload, and read state.
- **Notification Job** — A scheduled push: who, what it references, when it should fire, and its delivery status (`pending` | `queued` | `sent` | `failed` | `cancelled`).
- **Subscription** — A user's paid plan. Holds provider (`stripe` | `google_play` | `app_store`), provider's subscription identifier, status (`active` | `past_due` | `canceled` | `expired` | `trialing`), and current-period end. Mirrored onto User as plan/expiry for fast access checks.
- **Payment Event** — A provider webhook delivery, keyed uniquely by (provider, event id) to make replays harmless.
- **AI Job** — A user-submitted asynchronous AI request referencing uploaded images, with a status lifecycle and a link to its produced artifacts.
- **AI Artifact** — A produced AI result tied to a user and subject: a summary, a flashcard deck, or a list of important questions.
- **Audit Log** — A security-relevant event record (1-year retention).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new visitor can register, verify their email, sign in, and reach an empty workspace in under 3 minutes on a typical mobile connection.
- **SC-002**: 95% of read-heavy interactions a student performs in a normal session (open workspace, list subjects, view today's focus, open inbox) feel instant from the user's perspective (perceived response under 1 second on a typical mobile connection).
- **SC-003**: At least 99% of scheduled reminders are delivered within 60 seconds of their intended fire time over any rolling 7-day window.
- **SC-004**: 99% of plan transitions (free→premium on successful purchase, premium→free on confirmed cancellation/expiry) are reflected for the user within 60 seconds of the provider confirming the event.
- **SC-005**: 95% of submitted AI notes jobs complete (or surface a user-readable failure) within 3 minutes of submission.
- **SC-006**: Plan enforcement is correct in 100% of attempts: free users are blocked from over-limit subject creation and from premium-only endpoints, and premium users are never blocked from premium features while their subscription is active.
- **SC-007**: Streak calculations are correct in 100% of cases when computed in the user's own timezone, including across travel across timezones.
- **SC-008**: 100% of duplicate payment-provider event deliveries are no-ops (no double-charging effects, no double-grants of premium).
- **SC-009**: Zero cross-user data leaks: in every test that authenticates as user A and requests user B's resource by identifier, the response is a denial, never B's data.
- **SC-010**: The platform sustains the projected MVP user load (target: 10,000 concurrent active users, peaks of 1,000 requests per second on the hot read paths) without exceeding the perceived-latency goal in SC-002.
- **SC-011**: Every endpoint in the public API surface is invokable end-to-end from the documentation surface with bearer auth that persists across reloads, and every endpoint declares both its success response shape and its possible error shapes.
- **SC-012**: Deleted user accounts have all personal data removed from primary storage within the documented retention window (target: 30 days from soft-delete), verifiable by audit query.
- **SC-013**: The public API achieves at least **99.5% monthly availability** (no more than ~3.6 hours of downtime per calendar month), measured at the API gateway by successful responses to a synthetic health probe and to real client traffic.

## Assumptions

- The mobile client is the primary consumer; the API documentation surface (live "try-it-out" UI) is the primary manual testing surface; no separate API client collection is required.
- Authentication uses email + password and Google sign-in for the MVP; additional identity providers are out of scope for v1.
- Reward thresholds for streaks are fixed at 3, 7, 30, and 100 days for the MVP; making them configurable per user or per cohort is out of scope.
- Free-plan subject cap is fixed at 3 active subjects for the MVP; promotional overrides are out of scope.
- Notifications go to push and to an in-app inbox in the MVP; SMS and in-app banner systems are out of scope.
- AI features depend on a third-party large-language-model provider and an OCR provider; capacity and pricing of those providers are accepted constraints and inform the per-user AI rate limits.
- Inbox retention is 90 days; audit retention is 1 year; soft-deleted accounts are purged 30 days after deletion. These are industry-standard defaults and can be revisited later without breaking the spec.
- Localization beyond the user's chosen locale tag for date/time formatting is out of scope for v1; product copy is English-only initially.
- Admin-facing surfaces (operator dashboards beyond a queue-health board) are out of scope for the backend feature spec and tracked separately.
- Premium pricing, currencies, and entitlement tiers beyond a single "premium" tier are out of scope; the system models exactly one paid tier for the MVP.
