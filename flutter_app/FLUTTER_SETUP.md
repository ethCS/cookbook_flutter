# My Flutter Cookbook setup

This Flutter app lives in `flutter_app/` so the original web/Firebase files remain untouched.

## Run locally

```bash
cd flutter_app
flutter run -d chrome
# optional override:
# flutter run -d chrome --dart-define=RECAPTCHA_ENTERPRISE_KEY=YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY
```

## Build for hosting

```bash
cd flutter_app
flutter build web --release
firebase deploy --project myfluttercookbook --config firebase.flutter.json

# optional override:
# flutter build web --release --dart-define=RECAPTCHA_ENTERPRISE_KEY=YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY
```

## Secure mobile release build

```bash
cd flutter_app
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Firebase security checklist

- Firestore rules live in `firestore.flutter.rules`
- App Check is initialized in `lib/main.dart`
- Enable **Email/Password** sign-in in Firebase Console → Authentication → Sign-in method
- Enable reCAPTCHA Enterprise for the web app in Firebase Console → App Check
- After testing, turn on App Check enforcement for Firestore/Auth/Hosting-related resources
- The public reCAPTCHA **site key** is configured for the web client in `lib/main.dart`
- Keep the reCAPTCHA **secret key** out of source control and only in Firebase Console / server-side tooling

## Notes

- Recipe data comes from TheMealDB public API.
- User-specific data is stored in Firestore under `users/{uid}`.
- The UI is responsive and intended to work on both mobile and desktop.
