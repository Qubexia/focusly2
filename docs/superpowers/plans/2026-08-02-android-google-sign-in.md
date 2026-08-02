# Android Google Sign-In Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable end-to-end Google Sign-In on Android using the existing Flutter UI/Bloc and NestJS `/v1/auth/google` flow.

**Architecture:** Keep Focaly JWT sessions. Android obtains a Google `idToken` via `google_sign_in` with Web `serverClientId`; NestJS verifies that token with `google-auth-library` using the same Web Client ID (`GOOGLE_CLIENT_ID`). No Firebase Auth session migration.

**Tech Stack:** Flutter `google_sign_in` ^6.2.2, NestJS `GoogleAuthService`, Firebase project `focusly-9ac6a`, Android `applicationId` `com.zakerly.app`.

**Spec:** `docs/superpowers/specs/2026-08-02-android-google-sign-in-design.md`

## Global Constraints

- Platform: Android only; do not change iOS Google Sign-In setup.
- Package: Android `applicationId` is `com.zakerly.app` (not `com.example.focusly`).
- Flutter `GOOGLE_SERVER_CLIENT_ID` and backend `GOOGLE_CLIENT_ID` must be the identical Web OAuth client ID.
- Prefer minimal code changes; configuration is the primary deliverable.
- Do not commit secrets (`.env`, keystore passwords). `google-services.json` may be updated if it already lives in the repo.

## File map

| File | Responsibility |
|------|----------------|
| Firebase Console / Google Cloud Console | Web OAuth client + Android SHA-1 → regenerate clients |
| `focusly/android/app/google-services.json` | Android Firebase/OAuth clients for `com.zakerly.app` |
| `focaly-backend/.env` | `GOOGLE_CLIENT_ID` (local, gitignored) |
| `focusly/lib/core/config/auth_config.dart` | Reads `GOOGLE_SERVER_CLIENT_ID` dart-define |
| `focusly/lib/features/auth/presentation/bloc/auth_bloc.dart` | Google sign-in + logout `signOut` + config fail-fast |
| `focusly/lib/l10n/app_en.arb` / `app_ar.arb` | New config-missing error string |
| `.vscode/launch.json` (create if missing) | Dev run with dart-define |

---

### Task 1: Firebase / Google Cloud OAuth for Android

**Files:**
- Modify (replace): `focusly/android/app/google-services.json`
- External: Firebase Console project `focusly-9ac6a`, Google Cloud OAuth clients

**Interfaces:**
- Consumes: Android package `com.zakerly.app`; debug (and release if used) keystore SHA-1
- Produces: Web Client ID string `XXXX.apps.googleusercontent.com`; updated `google-services.json` where `client` entry for `com.zakerly.app` has non-empty `oauth_client`

- [ ] **Step 1: Print debug SHA-1**

From repo root (PowerShell), run:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Expected: a `SHA1:` fingerprint line (colon-separated hex). Copy it.

If a release keystore is configured in `focusly/android/key.properties`, also print that keystore’s SHA-1 the same way (different `-keystore` / `-alias` / passwords from `key.properties`).

- [ ] **Step 2: Register SHA-1 on the Android app**

In Firebase Console → Project `focusly-9ac6a` → Project settings → Your apps → Android app with package `com.zakerly.app`:

1. Add the debug SHA-1 (and release SHA-1 if available).
2. Save.

If no Android app exists for `com.zakerly.app`, add one with that package name first, then add SHA-1.

- [ ] **Step 3: Ensure a Web OAuth client exists**

In Google Cloud Console (same GCP project linked to Firebase) → APIs & Services → Credentials:

1. Confirm an OAuth 2.0 Client of type **Web application** exists.
2. Copy its Client ID (`….apps.googleusercontent.com`). This value is both:
   - backend `GOOGLE_CLIENT_ID`
   - Flutter `GOOGLE_SERVER_CLIENT_ID`

If missing, create **Web application** OAuth client (no redirect URIs required for mobile idToken verification). Also enable Google Sign-In / Identity Toolkit as needed for the Firebase project.

- [ ] **Step 4: Download and replace `google-services.json`**

From Firebase Project settings → download `google-services.json` and overwrite:

`focusly/android/app/google-services.json`

Verify the `com.zakerly.app` client block has `"oauth_client": [ { ... } ]` (not `[]`).

- [ ] **Step 5: Sanity check (no commit of secrets beyond the json already in tree)**

Run:

```powershell
Select-String -Path "focusly\android\app\google-services.json" -Pattern '"package_name"|oauth_client' 
```

Expected: `com.zakerly.app` present; `oauth_client` arrays no longer empty for that app.

Do **not** commit until Task 3/4 code is ready if you prefer one commit; otherwise:

```powershell
git add focusly/android/app/google-services.json
git commit -m "chore(android): refresh google-services.json with OAuth clients"
```

---

### Task 2: Wire backend `GOOGLE_CLIENT_ID`

**Files:**
- Modify (local only): `focaly-backend/.env`
- Verify mapping: `focaly-backend/src/config/env/jwt.config.ts` (`googleClientId: process.env.GOOGLE_CLIENT_ID`)
- Verify consumer: `focaly-backend/src/modules/auth/google-auth.service.ts`

**Interfaces:**
- Consumes: Web Client ID from Task 1
- Produces: `configService.get('jwt.googleClientId')` non-empty so `verifyIdToken` no longer throws “Google sign-in is not configured.”

- [ ] **Step 1: Set env var**

In `focaly-backend/.env`, set (replace with the real Web Client ID):

```env
GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Do not commit `.env`.

- [ ] **Step 2: Restart the NestJS API**

From `focaly-backend`:

```powershell
npm run start:dev
```

Expected: server boots without error.

- [ ] **Step 3: Confirm config is loaded (quick check)**

With the API running, temporarily call Google login with a dummy token (PowerShell):

```powershell
curl.exe -s -X POST http://localhost:3000/v1/auth/google -H "Content-Type: application/json" -d "{\"idToken\":\"invalid\",\"deviceId\":\"test-device\"}"
```

Expected: **not** `"Google sign-in is not configured."`  
Expected: unauthorized / invalid token style message (e.g. `"Google token is invalid."`).

If you still see “not configured”, the process did not pick up `.env` — restart and re-check the variable name spelling `GOOGLE_CLIENT_ID`.

---

### Task 3: Flutter fail-fast + Google `signOut` on logout

**Files:**
- Modify: `focusly/lib/l10n/app_en.arb`
- Modify: `focusly/lib/l10n/app_ar.arb`
- Modify: `focusly/lib/features/auth/presentation/bloc/auth_bloc.dart`
- Generated (via flutter): `focusly/lib/l10n/app_localizations*.dart`

**Interfaces:**
- Consumes: `AuthConfig.googleServerClientId` (`String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')`)
- Produces:
  - `AppLocalizations.authGoogleNotConfigured` (en/ar)
  - On `AuthGoogleLoginRequested`, if server client id empty → `AuthError(authGoogleNotConfigured)` without calling Google SDK
  - On `AuthLogoutRequested`, after repository logout → `await _googleSignIn.signOut()` (ignore errors)

- [ ] **Step 1: Add l10n strings**

In `focusly/lib/l10n/app_en.arb`, add next to the other Google auth keys:

```json
"authGoogleNotConfigured": "Google sign-in is not configured for this build. Set GOOGLE_SERVER_CLIENT_ID."
```

In `focusly/lib/l10n/app_ar.arb`:

```json
"authGoogleNotConfigured": "تسجيل الدخول عبر Google غير مضبوط لهذه النسخة. عيّن GOOGLE_SERVER_CLIENT_ID."
```

- [ ] **Step 2: Regenerate localizations**

From `focusly`:

```powershell
flutter gen-l10n
```

Expected: `authGoogleNotConfigured` getter appears on `AppLocalizations`.

- [ ] **Step 3: Update `AuthBloc._onGoogleLogin` fail-fast**

In `focusly/lib/features/auth/presentation/bloc/auth_bloc.dart`, at the start of `_onGoogleLogin` (after `emit(const AuthLoading());`), add:

```dart
if (AuthConfig.googleServerClientId.isEmpty) {
  emit(AuthError(message: AppL10n.current.authGoogleNotConfigured));
  return;
}
```

Keep the existing `GoogleSignIn` construction using `AuthConfig.googleServerClientId`.

- [ ] **Step 4: Sign out of Google on logout**

Replace `_onLogout` body with:

```dart
Future<void> _onLogout(
  AuthLogoutRequested event,
  Emitter<AuthState> emit,
) async {
  await _authRepository.logout();
  try {
    await _googleSignIn.signOut();
  } catch (_) {
    // Local session already cleared; ignore Google SDK errors.
  }
  emit(const AuthUnauthenticated());
}
```

- [ ] **Step 5: Analyze**

From `focusly`:

```powershell
flutter analyze lib/features/auth/presentation/bloc/auth_bloc.dart
```

Expected: no issues (or only pre-existing unrelated infos).

- [ ] **Step 6: Commit**

```powershell
git add focusly/lib/l10n/app_en.arb focusly/lib/l10n/app_ar.arb focusly/lib/l10n/app_localizations.dart focusly/lib/l10n/app_localizations_en.dart focusly/lib/l10n/app_localizations_ar.dart focusly/lib/features/auth/presentation/bloc/auth_bloc.dart
git commit -m "fix(auth): fail fast when Google client id missing and sign out on logout"
```

---

### Task 4: Dev launch config with `GOOGLE_SERVER_CLIENT_ID`

**Files:**
- Create or modify: `.vscode/launch.json`
- Reference (no change required): `focusly/lib/core/config/auth_config.dart`

**Interfaces:**
- Consumes: Web Client ID from Task 1
- Produces: A VS Code / Cursor launch config that passes `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` so `AuthConfig.googleServerClientId` is non-empty at runtime

- [ ] **Step 1: Add launch configuration**

Create `.vscode/launch.json` if missing, with at least:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "zakerly (Android + Google)",
      "request": "launch",
      "type": "dart",
      "program": "focusly/lib/main.dart",
      "cwd": "focusly",
      "toolArgs": [
        "--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
      ]
    }
  ]
}
```

Replace `YOUR_WEB_CLIENT_ID...` with the real Web Client ID.  
If the team prefers not to store the client id in git, keep the placeholder and document the CLI form in Step 2; do not put backend secrets here (Web Client ID is a public OAuth client id, acceptable in launch configs).

- [ ] **Step 2: Document CLI equivalent in a short comment in `auth_config.dart`**

Ensure `focusly/lib/core/config/auth_config.dart` header comment includes:

```dart
/// Example (Android):
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
/// Must match backend `GOOGLE_CLIENT_ID` (Firebase/Google Web client ID).
```

- [ ] **Step 3: Commit launch helper (optional if placeholder only)**

```powershell
git add .vscode/launch.json focusly/lib/core/config/auth_config.dart
git commit -m "chore(dev): launch config for Google Sign-In dart-define"
```

---

### Task 5: Manual end-to-end verification (Android)

**Files:** none (manual)

**Interfaces:**
- Consumes: Tasks 1–4 complete; API reachable from the device/emulator (`DevApiConfig` / `API_BASE_URL` as already used for email login)

- [ ] **Step 1: Run the app with dart-define**

From `focusly`:

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Expected: app installs on Android device/emulator.

- [ ] **Step 2: Google login from Login page**

1. Open Login.
2. Tap Continue with Google.
3. Pick a Google account.
4. Expected: `AuthAuthenticated` — home/shell loads; no `authGoogleTokenFailed` / `authGoogleNotConfigured`.

- [ ] **Step 3: Logout and re-login**

1. Logout.
2. Continue with Google again.
3. Expected: account picker appears (because of `signOut`); login succeeds again.

- [ ] **Step 4: Register page path**

1. Open Register.
2. Continue with Google with the same or another account.
3. Expected: same session success path (`AuthGoogleLoginRequested`).

- [ ] **Step 5: Negative check — missing dart-define**

Run once without the define:

```powershell
flutter run
```

Tap Google → Expected: `authGoogleNotConfigured` message (fail-fast), not a silent hang.

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| Web Client ID + SHA-1 + refresh `google-services.json` | Task 1 |
| Backend `GOOGLE_CLIENT_ID` | Task 2 |
| Flutter `GOOGLE_SERVER_CLIENT_ID` dart-define | Task 4 |
| Logout `GoogleSignIn.signOut` | Task 3 |
| Fail fast when server client id empty | Task 3 |
| Android-only / iOS untouched | All tasks (no iOS files) |
| Manual E2E acceptance | Task 5 |

## Self-review notes

- No iOS `Info.plist` / `GoogleService-Info.plist` steps (deferred by spec).
- Web Client ID must not be confused with the Android OAuth client id.
- Package under test is `com.zakerly.app`.
