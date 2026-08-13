### Task 2: Wire backend `GOOGLE_CLIENT_ID`

**Files:**
- Modify (local only): `focaly-backend/.env`
- Verify mapping: `focaly-backend/src/config/env/jwt.config.ts` (`googleClientId: process.env.GOOGLE_CLIENT_ID`)
- Verify consumer: `focaly-backend/src/modules/auth/google-auth.service.ts`

**Interfaces:**
- Consumes: Web Client ID from Task 1
- Produces: `configService.get('jwt.googleClientId')` non-empty so `verifyIdToken` no longer throws “Google sign-in is not configured.”

**Web Client ID (verbatim):**
`264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com`

- [ ] **Step 1: Set env var**

In `focaly-backend/.env`, set:

```env
GOOGLE_CLIENT_ID=264301190550-asllhnma6e86477cm9tckti0h03ln223.apps.googleusercontent.com
```

Do not commit `.env`. Do not store any client_secret.

- [ ] **Step 2: Restart the NestJS API** (if already running; otherwise start)

From `focaly-backend`:

```powershell
npm run start:dev
```

- [ ] **Step 3: Confirm config is loaded**

```powershell
curl.exe -s -X POST http://localhost:3000/v1/auth/google -H "Content-Type: application/json" -d "{\"idToken\":\"invalid\",\"deviceId\":\"test-device\"}"
```

Expected: **not** `"Google sign-in is not configured."`  
Expected: unauthorized / invalid token style message (e.g. `"Google token is invalid."`).

If the API is not running / port differs, check `focaly-backend` port from `.env` PORT or default and adjust. Report the exact response body.
