# Task 4 Report: Dev launch config with GOOGLE_SERVER_CLIENT_ID

**Status:** DONE

## Summary

Added VS Code/Cursor launch configuration for Android Google Sign-In development and documented the CLI `--dart-define` equivalent in `auth_config.dart`.

## Changes

### `.vscode/launch.json` (created)

New launch configuration **"zakerly (Android + Google)"**:
- `program`: `focusly/lib/main.dart`
- `cwd`: `focusly`
- `toolArgs`: `--dart-define=GOOGLE_SERVER_CLIENT_ID=264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com`

Note: `.vscode/` is listed in root `.gitignore`; file was force-added (`git add -f`) so it could be committed per task brief.

### `focusly/lib/core/config/auth_config.dart` (doc comment only)

Added Android CLI example and clarified backend ID requirement:

```dart
/// Example (Android):
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
/// Must match backend `GOOGLE_CLIENT_ID` (Firebase/Google Web client ID).
```

No runtime behavior changes; client ID is not hardcoded in Dart source.

## Verification

- [x] Launch config uses exact Web Client ID from brief
- [x] No `.env` or `client_secret` added
- [x] `AuthConfig` class unchanged (only doc comment)
- [x] Commit message matches brief exactly

## Commit

```
6cf315a chore(dev): launch config for Google Sign-In dart-define
```

Files in commit:
- `.vscode/launch.json`
- `focusly/lib/core/config/auth_config.dart`

## Concerns

- **`.gitignore` vs tracked launch.json:** Root `.gitignore` ignores `.vscode/`. The launch file is intentionally force-tracked for team sharing; consider adding an exception (e.g. `!.vscode/launch.json`) in a follow-up if desired.
- **No runtime test:** Launch config was not exercised via `flutter run` in this task; manual verification in Cursor/VS Code recommended.

## Out of scope (unchanged)

- `focusly/android/app/build.gradle.kts`
- `focusly/lib/firebase_options.dart`
- Other untracked/modified files in working tree
