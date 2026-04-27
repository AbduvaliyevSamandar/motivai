# MotivAI — Auth setup (Email OTP + Google Sign-In)

This guide walks you through wiring real email verification and Google login.
Both are **optional** — without configuration, the existing email+password
flow keeps working, but the new endpoints will return 503 / log to stdout.

## 1. Email OTP (Gmail SMTP)

### a. Create a Gmail App Password
1. Go to <https://myaccount.google.com/security>.
2. Turn on **2-Step Verification** (required for app passwords).
3. Visit <https://myaccount.google.com/apppasswords>.
4. App: **Mail**, Device: **Other → MotivAI**. Click **Generate**.
5. Copy the 16-character password (no spaces).

### b. Add Render env vars
On your Render service → **Environment** tab, add:

| Key | Value |
|-----|-------|
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USER` | `your.gmail@gmail.com` |
| `SMTP_PASSWORD` | the 16-char app password from step a |
| `SMTP_FROM_NAME` | `MotivAI` |
| `SMTP_FROM_EMAIL` | (optional, defaults to `SMTP_USER`) |

Save → Render auto-redeploys.

### c. Test
```bash
curl -X POST https://motivai-20s9.onrender.com/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"YOU@gmail.com","purpose":"register"}'
```
You should get `{"success": true, ...}` and an email with the code in seconds.

---

## 2. Google Sign-In

### a. Create OAuth client in Google Cloud Console
1. <https://console.cloud.google.com/> → create or select a project (e.g. **MotivAI**).
2. Enable the **Google+ API** (or just navigate to OAuth consent).
3. **OAuth consent screen** → External → fill app name, support email,
   add `email`, `profile`, `openid` scopes. Add yourself as test user.
4. **Credentials** → **Create credentials** → **OAuth client ID**:
   - **Web application** (used for token verification on the server, even
     for mobile clients): copy the **Web client ID**, e.g.
     `1234567890-abcdefg.apps.googleusercontent.com`.
   - For Android: also create an **Android client ID**. You'll need the
     SHA-1 of the signing key:
     ```
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
     Use package `uz.motivai.app`.
   - For iOS: create an **iOS client ID** if you ship to iOS.

### b. Add Render env vars (backend verifies the ID token)

| Key | Value |
|-----|-------|
| `GOOGLE_OAUTH_CLIENT_ID` | the **Web** client ID |
| `GOOGLE_OAUTH_AUDIENCES` | (optional) comma-separated extra audiences (Android/iOS client IDs) |

### c. Wire client side
1. In `lib/config/constants.dart`, set:
   ```dart
   static const googleClientId = '1234567890-abcdefg.apps.googleusercontent.com';
   ```
2. **Android extra step:** download `google-services.json` from the
   Cloud Console (it's offered when creating the Android client) and put
   it at `android/app/google-services.json`. Add the Google services
   plugin if it isn't already (`google_sign_in` doesn't strictly need it
   on Android, but Firebase-style apps do).
3. **iOS extra step:** drag `GoogleService-Info.plist` into `ios/Runner/`
   and add the `REVERSED_CLIENT_ID` scheme to `Info.plist`.

### d. Test
- Run the app, tap **Google bilan kirish** on login or register.
- Pick an account → backend returns the same token shape as email login.

---

## 3. Forgot password

Already wired client-side. Once SMTP is configured:
- Login screen → **Forgot password** → enter email → get code → enter new password → done.

---

## Troubleshooting

**`Email service not configured`** — SMTP env vars missing or wrong app password.

**`Google sign-in not configured` (503)** — backend `GOOGLE_OAUTH_CLIENT_ID` is empty.

**`Audience mismatch` (401)** — your app sent a token for client ID X, but the
backend only accepts client ID Y. Add X to `GOOGLE_OAUTH_AUDIENCES`.

**Android: `PlatformException(sign_in_failed)`** — usually wrong SHA-1 in the
Cloud Console Android client. Match the keystore you sign with.

**Mobile carrier blocks `*.onrender.com`** — see prior advice (Cloudflare WARP /
Private DNS).
