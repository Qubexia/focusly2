# Task 1: Firebase / Google Cloud OAuth for Android

## Status

**BLOCKED**

## Completed

- Read the debug keystore SHA-1: `0D:A0:28:84:97:C1:02:48:20:35:DF:61:9F:00:A9:07:4F:2E:E1:99`.
- Found `focusly/android/key.properties`, safely used it without reporting its passwords, and read the release upload-keystore SHA-1: `51:53:A3:CC:ED:4E:F0:AB:F3:70:CD:41:44:70:06:35:30:93:AA:3F`.
- Registered both SHA-1 values on Firebase Android app `1:264301190550:android:bc962634566d73e7f751b7` in project `focusly-9ac6a`.
- Verified through `firebase apps:android:sha:list` that both SHA-1 certificates are registered.
- Retrieved the existing Firebase Web app configuration for `1:264301190550:web:87f22e7354d14972f751b7`.

## Blocker

The Firebase Android SDK config was downloaded twice after certificate registration and the `com.zakerly.app` client still contains `"oauth_client": []`. The Firebase Web SDK config does not include an OAuth 2.0 Web Client ID, and `gcloud` is not installed in this environment. Consequently, the required Web Client ID cannot be obtained and replacing/committing `google-services.json` would not meet the task requirements.

**Web Client ID:** UNAVAILABLE — BLOCKED

## Required Human Step

In Google Cloud Console for project `focusly-9ac6a`, open **APIs & Services → Credentials**. Confirm or create an OAuth 2.0 client of type **Web application** (no redirect URI is required for mobile ID-token verification), then copy its `*.apps.googleusercontent.com` client ID. Allow the Firebase configuration to propagate, download a new Android `google-services.json`, and confirm the `com.zakerly.app` block has a non-empty `oauth_client` array. After that, rerun this task's download, sanity check, and commit steps.

## Commits

No commit was created because the required OAuth client configuration is not present.
