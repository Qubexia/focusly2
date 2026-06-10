# Zakerly — Flutter Frontend Implementation Plan

> Full backend-to-frontend mapping for the Zakerly Study Management App.
> **Backend:** NestJS + MongoDB + Redis + BullMQ  
> **Frontend:** Flutter (iOS + Android)

---

## 1. Architecture Overview

### 1.1 Flutter Architecture — Clean Architecture + BLoC

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp, routing, theme
│   ├── routes.dart                 # GoRouter config
│   └── di.dart                     # GetIt / Injectable DI setup
│
├── core/
│   ├── network/
│   │   ├── api_client.dart         # Dio instance, base URL, interceptors
│   │   ├── auth_interceptor.dart   # Attach Bearer, auto-refresh on 401
│   │   └── error_handler.dart      # Map API errors → domain failures
│   ├── storage/
│   │   ├── secure_storage.dart     # flutter_secure_storage (tokens)
│   │   └── prefs_storage.dart      # SharedPreferences (settings cache)
│   ├── theme/
│   │   ├── app_theme.dart          # Light + Dark ThemeData
│   │   ├── colors.dart             # Brand palette
│   │   └── typography.dart         # Google Fonts (Inter/Outfit)
│   ├── constants/
│   │   └── api_endpoints.dart      # All /v1/... paths
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── validators.dart
│   └── widgets/                    # Shared reusable widgets
│       ├── loading_overlay.dart
│       ├── error_banner.dart
│       ├── empty_state.dart
│       └── premium_gate.dart       # "Upgrade to Premium" bottom sheet
│
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   ├── subjects/
│   ├── study_schedules/
│   ├── pomodoro/
│   ├── streaks/
│   ├── planned_items/              # tasks, revisions, lectures, exams
│   ├── notifications/
│   ├── analytics/
│   ├── ai/
│   ├── subscription/
│   ├── profile/
│   └── settings/
│
└── gen/                            # Generated code (freezed, json_serializable)
```

Each feature follows:
```
feature/
├── data/
│   ├── models/          # JSON-serializable DTOs (freezed)
│   ├── datasources/     # Remote API calls via Dio
│   └── repositories/    # Impl of domain repo interface
├── domain/
│   ├── entities/        # Pure Dart classes
│   ├── repositories/    # Abstract interfaces
│   └── usecases/        # Single-responsibility use cases
└── presentation/
    ├── bloc/            # BLoC / Cubit
    ├── pages/           # Full screens
    └── widgets/         # Feature-specific widgets
```

### 1.2 Key Flutter Packages

| Category | Package |
|---|---|
| State Management | `flutter_bloc` |
| Routing | `go_router` |
| DI | `get_it` + `injectable` |
| Network | `dio` + `retrofit` |
| Models | `freezed` + `json_serializable` |
| Secure Storage | `flutter_secure_storage` |
| Local Storage | `shared_preferences` + `hive` |
| Push Notifications | `firebase_messaging` + `flutter_local_notifications` |
| Google Sign-In | `google_sign_in` |
| In-App Purchase | `in_app_purchase` |
| Charts | `fl_chart` |
| Calendar | `table_calendar` |
| Image Picker | `image_picker` |
| Animations | `lottie`, `flutter_animate` |
| Fonts | `google_fonts` |
| Timer | `circular_countdown_timer` or custom |

---

## 2. Screen Map — Every Backend Feature → Flutter Screen

### Legend
- 🔓 Public (no auth) | 🔒 Authenticated | 💎 Premium-only
- **API** = Backend endpoint consumed

---

### 2.1 🔓 Auth Module (11 endpoints → 6 screens)

| Screen | API Endpoints | Key UI Elements |
|---|---|---|
| **Splash Screen** | `GET /v1/users/me` (auto-login check) | Logo animation, auto-navigate |
| **Onboarding** | — | 3-slide carousel, "Get Started" CTA |
| **Login** | `POST /v1/auth/login` | Email + password fields, "Forgot Password?", Google button, "Sign Up" link |
| **Register** | `POST /v1/auth/register` | Name, email, password, confirm password, Google button |
| **Forgot Password** | `POST /v1/auth/forgot-password` | Email field, "Send Reset Link" |
| **Reset Password** | `POST /v1/auth/reset-password` | Deep link handler, new password + confirm |
| **Email Verification** | `POST /v1/auth/verify-email` | Deep link handler, success state |
| **Google Sign-In** | `POST /v1/auth/google` | Triggered from Login/Register via `google_sign_in` |

**BLoC: `AuthBloc`**
- States: `Initial`, `Loading`, `Authenticated(user, tokens)`, `Unauthenticated`, `Error(message)`
- Events: `LoginRequested`, `RegisterRequested`, `GoogleLoginRequested`, `LogoutRequested`, `RefreshRequested`

**Token Flow:**
1. Store `accessToken` + `refreshToken` in `flutter_secure_storage`
2. `AuthInterceptor` attaches Bearer header to every request
3. On 401 → call `POST /v1/auth/refresh` → retry original request
4. On refresh failure → emit `Unauthenticated` → navigate to Login

---

### 2.2 🔒 Home / Dashboard (composite screen)

| Section | API Endpoints | UI Elements |
|---|---|---|
| Greeting header | `GET /v1/users/me` | "Good morning, {name}" + avatar |
| Today's stats | `GET /v1/pomodoro/today` | Focus minutes ring, sessions count |
| Streak badge | `GET /v1/streaks/me` | 🔥 streak counter + flame animation |
| Quick actions | — | "Start Focus", "Add Task", "View Schedule" pills |
| Upcoming items | `GET /v1/schedules?from=today&to=today`, `GET /v1/tasks?from=today&to=today` | Horizontal scrollable cards |
| Subjects grid | `GET /v1/subjects` | Color-coded cards with progress rings |

**BLoC: `HomeCubit`** — Fetches all data in parallel on init.

---

### 2.3 🔒 Subjects Module (8 endpoints → 3 screens)

| Screen | API Endpoints | UI |
|---|---|---|
| **Subjects List** | `GET /v1/subjects` | Grid of colored cards with progress %, FAB to add. Free-plan shows "3/3" counter |
| **Subject Detail** | `GET /v1/subjects/:id`, `GET /v1/subjects/:id/progress`, `GET /v1/subjects/:id/chapters` | Header with color/icon, progress bar, chapters list with checkboxes |
| **Create/Edit Subject** | `POST /v1/subjects`, `PATCH /v1/subjects/:id` | Bottom sheet: name, color picker, icon selector, daily target slider |
| **Chapter Management** | `POST /v1/subjects/:id/chapters`, `PATCH /v1/subjects/:id/chapters/:chId` | Inline within Subject Detail. Reorderable list, tap-to-complete |

**Premium Gate:** On `POST /v1/subjects` → if 403 `SUBJECT_LIMIT_REACHED` → show `PremiumGateSheet`

**BLoC: `SubjectsCubit`**
- `loadSubjects()`, `createSubject()`, `updateSubject()`, `archiveSubject()`, `toggleChapter()`

---

### 2.4 🔒 Study Schedules Module (5 endpoints → 2 screens)

| Screen | API Endpoints | UI |
|---|---|---|
| **Weekly Calendar** | `GET /v1/schedules/calendar?from=&to=` | `table_calendar` week view, colored blocks per subject, tap to view detail |
| **Schedule Detail / Create** | `POST /v1/subjects/:subjectId/schedules`, `PATCH /v1/schedules/:id`, `DELETE /v1/schedules/:id` | Bottom sheet: title, subject picker, start/end time pickers, days-of-week chips, reminder toggle + offset |

**BLoC: `SchedulesCubit`** — Tracks selected week range, fetches on range change.

---

### 2.5 🔒 Pomodoro Module (7 endpoints → 2 screens)

| Screen | API Endpoints | UI |
|---|---|---|
| **Pomodoro Timer** | `POST /v1/pomodoro/start`, `POST /:id/pause`, `POST /:id/resume`, `POST /:id/complete`, `POST /:id/abort` | Full-screen focus UI: large circular countdown, subject label, pause/resume/stop buttons, cycle indicator dots, ambient animation |
| **Pomodoro History** | `GET /v1/pomodoro/history?from=&to=`, `GET /v1/pomodoro/today` | List of past sessions grouped by date, today's summary card at top |

**Timer Logic (client-side):**
- `PomodoroBloc` manages local countdown via `Timer.periodic`
- On cycle complete → API call `POST /v1/pomodoro/:id/complete`
- Auto-transition focus → break → focus
- Respect `focusMinutes` and `breakMinutes` from settings

**Notifications:** Schedule local notification at timer end via `flutter_local_notifications`

---

### 2.6 🔒 Streaks Module (1 endpoint → embedded widget)

| Component | API Endpoint | UI |
|---|---|---|
| **Streak Widget** (Home) | `GET /v1/streaks/me` | Fire icon + current count, "Best: {longest}" subtitle |
| **Streak Detail Sheet** | `GET /v1/streaks/me` | Bottom sheet: current, longest, points, reward badges (3d, 7d, 30d, 100d milestones) |

No separate screen — embedded in Home + Profile.

---

### 2.7 🔒 Planned Items Module (24 endpoints → 4 screens)

All four kinds (tasks, revisions, lectures, exams) share the same UI pattern with different icons/colors:

| Screen | API Endpoints | UI |
|---|---|---|
| **Daily Planner** | `GET /v1/tasks`, `GET /v1/revisions`, `GET /v1/lectures`, `GET /v1/exams` (all filtered by date) | Single screen, tab bar: Tasks \| Revisions \| Lectures \| Exams. Each tab shows a date-filterable list |
| **Item Detail** | `GET /v1/{kind}/:id` | Bottom sheet: title, subject, date, time, notes, reminder settings |
| **Create/Edit Item** | `POST /v1/{kind}`, `PATCH /v1/{kind}/:id` | Bottom sheet form: title, subject picker, date/time pickers, recurrence selector (once/daily/weekly), reminder toggle |
| **Complete Item** | `POST /v1/{kind}/:id/complete` | Swipe-to-complete or checkbox tap. Show points earned toast |

**BLoC: `PlannedItemsCubit`** — Parameterized by `kind`, manages CRUD + completion.

---

### 2.8 🔒 Notifications Module (6 endpoints → 1 screen + system push)

| Screen | API Endpoints | UI |
|---|---|---|
| **Notification Inbox** | `GET /v1/notifications`, `PATCH /v1/notifications/:id/read`, `POST /v1/notifications/read-all`, `DELETE /v1/notifications/:id` | List with unread badge dot, swipe-to-delete, "Mark All Read" action, pull-to-refresh |
| **Push Notifications** | `POST /v1/users/me/fcm-token` (registration) | `firebase_messaging` handles foreground/background/terminated states |
| **Notification Preferences** | `GET /v1/notifications/preferences`, `PATCH /v1/notifications/preferences` | Toggle switches in Settings screen: Reminders, Streak alerts, Marketing |

**FCM Setup:**
1. On app launch → get FCM token → `POST /v1/users/me/fcm-token`
2. Listen `onTokenRefresh` → re-register
3. Foreground: show in-app banner
4. Background/Terminated: system notification → tap opens relevant screen via deep link

---

### 2.9 💎 Analytics Module (4 endpoints → 1 screen, 4 tabs)

| Tab | API Endpoint | UI |
|---|---|---|
| **Summary** | `GET /v1/analytics/summary?from=&to=` | KPI cards: total minutes, sessions, tasks completed. Date range picker at top |
| **By Subject** | `GET /v1/analytics/by-subject?from=&to=` | Horizontal bar chart (fl_chart), one bar per subject, color-coded |
| **Heatmap** | `GET /v1/analytics/heatmap?year=` | GitHub-style contribution grid, 365 cells, color intensity = minutes |
| **Performance** | `GET /v1/analytics/performance?from=&to=` | Completion rate gauge, streak retention line chart |

**Free vs Premium:**
- Free: only current week range allowed (enforced by backend)
- Premium: full date-range picker, all tabs
- On 403 `PREMIUM_REQUIRED` → show upgrade prompt

**BLoC: `AnalyticsCubit`** — Manages selected date range, fetches per-tab data.

---

### 2.10 💎 AI Notes Module (3 endpoints → 2 screens)

| Screen | API Endpoints | UI |
|---|---|---|
| **AI Notes Hub** | `GET /v1/ai/artifacts?subjectId=` | List of generated artifacts grouped by subject. Each card shows: summary preview, flashcard count, question count |
| **New AI Job** | `POST /v1/uploads/presign`, (upload to S3), `POST /v1/ai/notes/jobs` | Step 1: Pick/capture images. Step 2: Select subject. Step 3: Submit → show progress. Poll `GET /v1/ai/notes/jobs/:id` until `completed` |
| **Artifact Viewer** | — (data from artifacts list) | Tabbed view: Summary (rich text), Flashcards (swipeable cards, flip animation), Questions (expandable list with difficulty badges) |

**Flow:**
1. User taps "Generate Notes" → image picker (camera/gallery, multi-select)
2. Upload each image via presigned S3 URL
3. Submit job with image keys
4. Show polling progress indicator
5. On complete → navigate to Artifact Viewer

**BLoC: `AiNotesCubit`** — Manages job submission, polling, artifact listing.

---

### 2.11 🔒 Subscription Module (6 endpoints → 1 screen)

| Screen | API Endpoints | UI |
|---|---|---|
| **Premium / Paywall** | `GET /v1/subscription/me`, `POST /v1/subscription/iap/google/verify`, `POST /v1/subscription/iap/apple/verify`, `POST /v1/subscription/cancel` | Full-screen paywall: feature comparison (Free vs Premium), pricing, CTA buttons. Post-purchase: manage subscription screen |

**In-App Purchase Flow (Flutter):**
1. Use `in_app_purchase` package
2. Load products → show pricing
3. On purchase complete → send receipt to backend for verification
4. Backend updates `user.plan` → refresh user profile locally

**BLoC: `SubscriptionCubit`**
- `loadSubscription()`, `purchasePremium()`, `restorePurchases()`, `cancelSubscription()`

---

### 2.12 🔒 Profile & Settings (3 endpoints → 2 screens)

| Screen | API Endpoints | UI |
|---|---|---|
| **Profile** | `GET /v1/users/me`, `PATCH /v1/users/me`, `POST /v1/users/me/avatar` | Avatar (tap to change), name edit, email (read-only), plan badge, total points, streak, "Edit Profile" CTA |
| **Settings** | `PATCH /v1/users/me/settings`, `GET /v1/auth/sessions`, `DELETE /v1/auth/sessions/:id` | Sections: Account (locale, timezone), Notifications (toggle switches), Focus Mode toggle, Active Devices list (swipe to revoke), Danger Zone (delete account, logout all) |
| **Delete Account** | `DELETE /v1/users/me` | Confirmation dialog with typed-confirm |

---

### 2.13 🔒 Uploads Module (2 endpoints → no standalone screen)

Used internally by:
- **Avatar upload** (Profile screen)
- **AI Notes image upload** (AI screen)

Utility class: `UploadService`
1. `POST /v1/uploads/presign` → get presigned URL
2. `PUT` file directly to S3
3. `POST /v1/uploads/confirm` → finalize

---

## 3. Navigation Map

```
App Launch
  │
  ├── [No Token] → Onboarding → Login/Register
  │
  └── [Has Token] → Main Shell (BottomNav)
        │
        ├── 🏠 Home (Dashboard)
        │     ├── → Pomodoro Timer
        │     ├── → Subject Detail
        │     └── → Daily Planner
        │
        ├── 📅 Schedule (Calendar)
        │     └── → Create/Edit Schedule
        │
        ├── ▶️ Focus (Pomodoro)
        │     ├── → Timer Screen
        │     └── → History
        │
        ├── 📊 Analytics (Premium)
        │     └── → Paywall (if free)
        │
        └── 👤 Profile
              ├── → Settings
              ├── → Notification Inbox
              ├── → Premium/Subscription
              ├── → AI Notes Hub
              └── → Active Devices
```

**Bottom Navigation Tabs:** Home | Schedule | Focus (center, elevated) | Analytics | Profile

---

## 4. Implementation Phases

### Phase 1 — Foundation (Week 1-2)

| Task | Details | Priority |
|---|---|---|
| Project scaffold | `flutter create`, folder structure, packages | P0 |
| Theme system | Colors, typography (Google Fonts), light/dark mode | P0 |
| DI setup | `get_it` + `injectable` configuration | P0 |
| Network layer | Dio client, auth interceptor, error handler, retry logic | P0 |
| Secure storage | Token persistence, auto-login check | P0 |
| Auth screens | Login, Register, Forgot Password | P0 |
| Google Sign-In | `google_sign_in` integration | P0 |
| Navigation shell | `go_router` with bottom nav, auth redirect | P0 |

**Deliverable:** User can register, login (email + Google), see empty Home.

---

### Phase 2 — Core Habit Loop (Week 3-4)

| Task | Details | Priority |
|---|---|---|
| Home dashboard | Greeting, today's stats, quick actions | P0 |
| Subjects CRUD | List, create, edit, archive, color picker | P0 |
| Chapters | Inline chapter list, checkbox completion | P0 |
| Pomodoro timer | Full-screen timer, pause/resume/complete/abort | P0 |
| Pomodoro history | Session list, today's summary | P1 |
| Streaks widget | Home card + detail bottom sheet | P0 |
| Subject limit gate | Show upgrade prompt on 403 | P0 |

**Deliverable:** User can create subjects, run pomodoro sessions, see streaks grow.

---

### Phase 3 — Planning & Scheduling (Week 5-6)

| Task | Details | Priority |
|---|---|---|
| Weekly calendar | `table_calendar` integration, schedule blocks | P0 |
| Schedule CRUD | Create/edit/delete study schedules | P0 |
| Daily planner | Tabs: Tasks, Revisions, Lectures, Exams | P0 |
| Planned item CRUD | Create/edit/complete/delete for all 4 kinds | P0 |
| Swipe-to-complete | Gesture-based task completion | P1 |
| Points & rewards | Toast on completion with points earned | P1 |

**Deliverable:** Full planning workflow. User can schedule study sessions and track tasks.

---

### Phase 4 — Notifications & Engagement (Week 7-8)

| Task | Details | Priority |
|---|---|---|
| FCM integration | `firebase_messaging` setup, token registration | P0 |
| Push handling | Foreground banners, background tap-to-open, deep links | P0 |
| Notification inbox | List screen with read/unread, mark-all, delete | P0 |
| Notification prefs | Toggle switches in settings | P1 |
| Local notifications | Timer-end alerts via `flutter_local_notifications` | P0 |
| Profile screen | Avatar, name edit, plan badge | P1 |
| Settings screen | Locale, timezone, focus mode, devices, logout | P1 |

**Deliverable:** User receives push reminders, manages notification preferences.

---

### Phase 5 — Monetization (Week 9-10)

| Task | Details | Priority |
|---|---|---|
| Paywall screen | Feature comparison, pricing, CTA | P0 |
| In-App Purchase | `in_app_purchase` for iOS + Android | P0 |
| Receipt verification | Send to backend, handle plan upgrade | P0 |
| Premium gate UI | Reusable bottom sheet for blocked features | P0 |
| Subscription management | View status, cancel, restore | P1 |
| Analytics — Summary | KPI cards with date range picker | P0 |
| Analytics — By Subject | Bar chart via `fl_chart` | P1 |
| Analytics — Heatmap | Contribution grid widget | P1 |
| Analytics — Performance | Gauge + line chart | P2 |

**Deliverable:** Premium subscription fully functional. Analytics available for premium users.

---

### Phase 6 — AI & Polish (Week 11-12)

| Task | Details | Priority |
|---|---|---|
| AI Notes Hub | Artifact listing per subject | P0 |
| Image upload flow | Camera/gallery → presigned S3 upload | P0 |
| AI job submission | Submit + polling with progress UI | P0 |
| Artifact viewer | Summary, flashcards (flip anim), questions | P0 |
| Onboarding carousel | 3-screen intro with Lottie animations | P1 |
| Micro-animations | Page transitions, hero animations, shimmer loading | P1 |
| Error states | Empty states, retry banners, offline detection | P1 |
| App icon & splash | Branded launch screen | P1 |
| Testing | Widget tests, BLoC tests, integration tests | P1 |

**Deliverable:** Full feature parity with backend. Production-ready app.

---

## 5. Backend ↔ Frontend API Contract Summary

### 5.1 All Endpoints (68 total)

| Module | Endpoints | Flutter Feature |
|---|---|---|
| **Auth** (11) | register, login, google, refresh, logout, logout-all, forgot-password, reset-password, verify-email, sessions, revoke-session | Auth screens + Settings |
| **Users** (6) | me (GET/PATCH), settings, avatar, fcm-token, delete | Profile + Settings |
| **Subjects** (8) | CRUD + chapters CRUD + progress | Subjects screens |
| **Schedules** (5) | create (under subject), list, calendar, update, delete | Calendar screen |
| **Pomodoro** (7) | start, pause, resume, complete, abort, today, history | Timer + History |
| **Streaks** (1) | me | Home widget + Profile |
| **Tasks** (6) | CRUD + complete | Daily Planner tab |
| **Revisions** (6) | CRUD + complete | Daily Planner tab |
| **Lectures** (6) | CRUD + complete | Daily Planner tab |
| **Exams** (6) | CRUD + complete | Daily Planner tab |
| **Notifications** (6) | list, read, read-all, delete, prefs GET/PATCH | Inbox + Settings |
| **Analytics** (4) | summary, by-subject, heatmap, performance | Analytics tabs |
| **Subscription** (6) | me, stripe/checkout, stripe/portal, webhook, iap/google, iap/apple, cancel | Paywall + Management |
| **AI** (3) | submit job, get job, list artifacts | AI Notes screens |
| **Uploads** (2) | presign, confirm | Used by Avatar + AI |
| **Health** (1) | ready | Dev/debug only |

### 5.2 Error Handling Strategy

| Backend Error Code | Flutter Behavior |
|---|---|
| `401 Unauthorized` | Auto-refresh token → retry. On fail → redirect to Login |
| `403 SUBJECT_LIMIT_REACHED` | Show `PremiumGateSheet` |
| `403 PREMIUM_REQUIRED` | Show `PremiumGateSheet` |
| `429 AI_RATE_LIMIT` | Show "Try again in X minutes" snackbar |
| `429 Too Many Requests` | Show rate-limit snackbar with retry timer |
| `400 / 422 Validation` | Highlight form fields with error messages |
| `404 Not Found` | Show empty state or navigate back |
| `500 Server Error` | Show retry banner with "Something went wrong" |

### 5.3 Offline Strategy

| Approach | Details |
|---|---|
| Cache-first reads | Cache subjects, schedules, streak in Hive. Show cached → fetch fresh |
| Optimistic writes | Show UI update immediately, revert on API failure |
| Queue offline actions | For task completion, use a local queue that syncs when online |
| Connectivity monitor | `connectivity_plus` → show offline banner |

---

## 6. Design System Specifications

### 6.1 Color Palette

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | `#6C5CE7` | `#A29BFE` | Buttons, active states, FABs |
| `secondary` | `#00B894` | `#55EFC4` | Success, streaks, completion |
| `surface` | `#FFFFFF` | `#1E1E2E` | Cards, sheets |
| `background` | `#F8F9FA` | `#121218` | Screen backgrounds |
| `error` | `#E17055` | `#FF7675` | Errors, destructive actions |
| `premium` | `#FDCB6E` | `#FFEAA7` | Premium badges, paywall CTA |

### 6.2 Subject Colors (User-selectable)

`#FFB020`, `#6C5CE7`, `#00B894`, `#E17055`, `#0984E3`, `#D63031`, `#00CEC9`, `#E84393`, `#636E72`, `#2D3436`

### 6.3 Typography

| Style | Font | Size | Weight |
|---|---|---|---|
| Headline Large | Outfit | 28sp | Bold |
| Headline Medium | Outfit | 24sp | SemiBold |
| Title | Inter | 20sp | SemiBold |
| Body | Inter | 16sp | Regular |
| Label | Inter | 14sp | Medium |
| Caption | Inter | 12sp | Regular |

### 6.4 Component Specs

| Component | Spec |
|---|---|
| Cards | 16px radius, 1px border `surface`, elevation 2 |
| Bottom Sheets | 24px top radius, drag handle |
| Buttons | 12px radius, 48px height, `primary` fill |
| Inputs | 12px radius, outlined, 48px height |
| FAB | 56px, `primary`, centered elevation 6 |
| Avatar | 48px (nav), 80px (profile), circular clip |
| Spacing | 8px grid system |

---

## 7. Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| State management | `flutter_bloc` | Predictable, testable, separation of concerns |
| Routing | `go_router` | Declarative, deep linking support, shell routes for bottom nav |
| DI | `get_it` | Simple, no code generation required for basic setup |
| HTTP | `dio` | Interceptors for auth, retry, logging |
| Models | `freezed` | Immutable, union types, copyWith, JSON serialization |
| Local DB | `hive` | Fast, lightweight, good for offline cache |
| Timer | Custom `Ticker` | More control than countdown packages for pomodoro |
| Charts | `fl_chart` | Highly customizable, performant |
| Calendar | `table_calendar` | Week/month views, customizable cells |

---

## 8. Testing Strategy

| Level | Target | Tools |
|---|---|---|
| Unit | BLoCs, UseCases, Repositories | `bloc_test`, `mockito` |
| Widget | Individual screens, form validation | `flutter_test` |
| Integration | Full flows (auth → create subject → start pomodoro) | `integration_test` |
| Golden | Visual regression on key screens | `golden_toolkit` |

Coverage target: **≥ 70%** on BLoCs and UseCases.

---

## 9. Checklist — Definition of Done per Feature

- [ ] All CRUD operations work end-to-end with backend
- [ ] Loading, error, and empty states implemented
- [ ] Pull-to-refresh on list screens
- [ ] Optimistic UI where applicable
- [ ] Premium gate shows for restricted features
- [ ] Dark mode support
- [ ] Responsive to different screen sizes
- [ ] BLoC unit tests written
- [ ] No hardcoded strings (localization-ready)
