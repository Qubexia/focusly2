# Task 3 Report: Flutter fail-fast + Google signOut on logout

## Status

**DONE**

## Summary

Implemented fail-fast Google sign-in when `GOOGLE_SERVER_CLIENT_ID` is missing, added localized error strings (en/ar), and ensured Google SDK sign-out runs on logout.

## Changes

### 1. l10n strings (en/ar)

Added `authGoogleNotConfigured` to:
- `focusly/lib/l10n/app_en.arb`
- `focusly/lib/l10n/app_ar.arb`

### 2. Regenerated localizations

Ran `flutter gen-l10n` from `focusly/`. Generated getters on:
- `app_localizations.dart`
- `app_localizations_en.dart`
- `app_localizations_ar.dart`

### 3. AuthBloc fail-fast

In `_onGoogleLogin`, after `emit(const AuthLoading())`, added check for empty `AuthConfig.googleServerClientId` that emits `AuthError` with `authGoogleNotConfigured` and returns without calling Google SDK.

### 4. Google signOut on logout

Updated `_onLogout` to call `await _googleSignIn.signOut()` after repository logout, wrapped in try/catch to ignore Google SDK errors.

## Verification

```powershell
flutter analyze lib/features/auth/presentation/bloc/auth_bloc.dart
```

Result: **No issues found!**

## Commit

- **SHA:** `37b8761`
- **Message:** `fix(auth): fail fast when Google client id missing and sign out on logout`
- **Files:** 6 changed, 25 insertions(+)

## Concerns

None.
