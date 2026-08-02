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
