# Android Google Sign-In — Design Spec

**Date:** 2026-08-02  
**Status:** Approved for planning  
**Scope:** Android only (iOS deferred)

## Problem

Google Sign-In UI and backend logic already exist, but OAuth configuration is empty. On Android the button cannot complete a real login: no Web Client ID is wired into Flutter or the API, and `google-services.json` has empty `oauth_client` arrays (SHA fingerprints not registered).

## Goal

A user on Android can tap **Continue with Google** on Login/Register, pick a Google account, and receive a Focaly session (`access` + `refresh` tokens) via the existing `POST /v1/auth/google` endpoint.

## Non-goals

- iOS Google Sign-In (`GoogleService-Info.plist`, URL schemes)
- Migrating auth to Firebase Auth as the session source of truth
- Changing Google account linking UX beyond what `AuthService.googleLogin` already does
- Production secrets on Render (can reuse the same Client ID later; not required for this delivery)

## Current state (keep)

| Layer | Status |
|-------|--------|
| Flutter button + `AuthGoogleLoginRequested` | Present |
| `google_sign_in` + `AuthBloc._onGoogleLogin` | Present; needs non-empty `serverClientId` |
| `AuthRepository` / `POST /v1/auth/google` | Present |
| NestJS `GoogleAuthService.verifyIdToken` | Present; needs `GOOGLE_CLIENT_ID` |
| User upsert / email merge by verified email | Present |

## Architecture

```text
[Android App]
  GoogleSignIn(serverClientId = WEB_CLIENT_ID)
       → idToken
       → POST /v1/auth/google { idToken, deviceId, fcmToken? }
[NestJS]
  GoogleAuthService.verifyIdToken(audience = GOOGLE_CLIENT_ID)
       → upsert/merge User
       → issue session tokens
```

**Invariant:** Flutter `GOOGLE_SERVER_CLIENT_ID` and backend `GOOGLE_CLIENT_ID` must be the **same Web OAuth client ID** (`*.apps.googleusercontent.com`).

## Configuration work

1. **Firebase / Google Cloud** (project `focusly-9ac6a`)
   - Ensure a **Web** OAuth 2.0 client exists (this is the server/client audience for `idToken`).
   - For Android app `com.zakerly.app`, register **debug SHA-1** (and **release SHA-1** if a release keystore is used locally).
   - Re-download `google-services.json` so `oauth_client` is non-empty for `com.zakerly.app`.

2. **Backend** (`focaly-backend/.env`)
   - Set `GOOGLE_CLIENT_ID=<Web Client ID>`.

3. **Flutter (Android runs)**
   - Pass `--dart-define=GOOGLE_SERVER_CLIENT_ID=<Web Client ID>` for `run` / `build apk` / `build appbundle`.
   - Document the flag (e.g. launch config or short note in existing run docs) so local runs do not omit it.

## Code changes (minimal)

1. **Logout hygiene (recommended):** On `AuthLogoutRequested`, call `GoogleSignIn.signOut()` so the next Google login can pick another account.
2. **Fail fast (optional but useful):** If `AuthConfig.googleServerClientId` is empty at Google login time, emit a clear configuration error instead of a generic failure / null `idToken`.
3. **No rewrite** of auth screens, repository contract, or NestJS google login flow unless a config bug is found during wiring.

## Error handling

| Case | Expected UX |
|------|-------------|
| User cancels Google picker | Return to unauthenticated; no error toast required |
| Missing `serverClientId` / null `idToken` | Clear error (config or token failure strings already in l10n) |
| Backend `GOOGLE_CLIENT_ID` empty | API: `Google sign-in is not configured.` |
| Invalid token / wrong audience | API: `Google token is invalid.` |
| Network / Dio errors | Existing `_extractErrorMessage` path |

## Testing (manual, Android)

1. Backend running with non-empty `GOOGLE_CLIENT_ID`.
2. App run with matching `GOOGLE_SERVER_CLIENT_ID`.
3. Login screen → Continue with Google → select account → land authenticated.
4. Register screen → same path works (same event).
5. Logout → Google Sign-In again can show account picker (after `signOut`).
6. Repeat with a second Google account; confirm separate Focaly users (or merge when email already verified and linked per existing rules).

## Risks

- Wrong client type (Android client used as `serverClientId`) → null/invalid `idToken`.
- SHA-1 not matching the installed build’s signing key → Google Sign-In fails before the API call.
- Package mismatch (`com.example.focusly` vs `com.zakerly.app`) → use `applicationId` `com.zakerly.app` everywhere for this work.

## Acceptance criteria

- [ ] Android Google Sign-In completes end-to-end against the local/dev API.
- [ ] `google-services.json` for `com.zakerly.app` includes at least one `oauth_client`.
- [ ] Backend and Flutter share the same Web Client ID.
- [ ] iOS is untouched beyond “out of scope”.
