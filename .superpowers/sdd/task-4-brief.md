### Task 4: Dev launch config with `GOOGLE_SERVER_CLIENT_ID`

**Files:**
- Create or modify: `.vscode/launch.json`
- Reference: `focusly/lib/core/config/auth_config.dart`

**Interfaces:**
- Consumes: Web Client ID
- Produces: VS Code / Cursor launch config that passes `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`

**Web Client ID (verbatim):**
`264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com`

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
        "--dart-define=GOOGLE_SERVER_CLIENT_ID=264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com"
      ]
    }
  ]
}
```

If `.vscode/launch.json` already exists, merge this configuration into `configurations` without removing unrelated configs.

- [ ] **Step 2: Document CLI equivalent in `auth_config.dart`**

Ensure `focusly/lib/core/config/auth_config.dart` header comment includes:

```dart
/// Example (Android):
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
/// Must match backend `GOOGLE_CLIENT_ID` (Firebase/Google Web client ID).
```

Keep existing class behavior; only improve the doc comment as needed (you may include the real client id in launch.json only, not hardcode it into Dart source).

- [ ] **Step 3: Commit**

```powershell
git add .vscode/launch.json focusly/lib/core/config/auth_config.dart
git commit -m "chore(dev): launch config for Google Sign-In dart-define"
```
