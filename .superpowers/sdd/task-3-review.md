# Task 3 Review: Flutter fail-fast + Google signOut on logout

## Verdicts
1. **Spec compliance:** ✅ (100% compliant with requirements)
2. **Task quality:** Approved (Clean, minimal, and fully functional changes)

## Summary of Changes Under Review
The implementer has successfully completed all requested steps for Task 3:
- **l10n Addition:** Added `authGoogleNotConfigured` keys in both `app_en.arb` and `app_ar.arb` with the correct localized strings.
- **Localization Generation:** Ran `flutter gen-l10n` to successfully regenerate `app_localizations.dart`, `app_localizations_ar.dart`, and `app_localizations_en.dart`.
- **Fail-fast Guard in AuthBloc:** Implemented the check for empty `AuthConfig.googleServerClientId` right after the loading state is emitted in `_onGoogleLogin`, successfully preventing unnecessary Google SDK initialization when not configured.
- **Sign-out on Logout:** Updated `_onLogout` to sign out using `_googleSignIn.signOut()`, properly catching and ignoring Google SDK errors.
- **Git Commit:** Committed the exact set of changed files with the requested message: `fix(auth): fail fast when Google client id missing and sign out on logout` under SHA `37b8761`.

## Findings
- **Critical:** None.
- **Important:** None.
- **Minor:** None.

## Conclusion
The implementation is solid, matches the required spec perfectly, introduces no regression, and is fully approved.
