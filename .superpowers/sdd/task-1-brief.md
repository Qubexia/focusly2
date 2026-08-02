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
