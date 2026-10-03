# Customer social sign-in setup

## Google

The Customer app uses `google_sign_in 6.2.2` so it remains compatible with the
current Dart 3.4.4 toolchain.

Create Google OAuth credentials for:

- Android package: `com.getincoffee.getin_coffee` plus the debug/release SHA fingerprints.
- Web/server client: pass this at runtime as `GOOGLE_SERVER_CLIENT_ID`.
- iOS client: pass as `GOOGLE_IOS_CLIENT_ID` and add its reversed URL scheme in Xcode/Info.plist when the iOS credential is created.

Example local Android run:

```bash
flutter run -d 569558720013 \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Laravel must use the same client IDs in `.env`.

## Apple

The iOS Runner includes the Sign in with Apple entitlement. Configure the App ID
for `com.getincoffee.getinCoffee` in Apple Developer and enable Sign in with Apple.

For Android, Apple requires a Service ID and a public HTTPS return URL. Set:

- `APPLE_SERVICE_ID`
- `APPLE_REDIRECT_URI=https://YOUR_DOMAIN/api/v1/customer/auth/apple/callback`

The local `127.0.0.1` environment cannot be used as Apple's Android redirect URI.

## OTP

Laravel enforces a minimum 30-second resend cooldown. The Customer OTP screen
shows a countdown and keeps Resend disabled until the server cooldown expires.
