# My Flutter Cookbook

A secure Flutter rebuild of the cookbook app using **TheMealDB** and **Firebase**.

## Live site

- Hosted URL: `https://myfluttercookbook.web.app`
- Best viewed on: **mobile or desktop** (responsive layout supported)

## Features

- Browse featured meals and categories
- Search recipes from the public MealDB API
- View recipe details and ingredients
- Sign in with Firebase Authentication
- Save favorites to Firestore
- Create and delete your own custom recipes
- Toggle light, dark, or system theme

## Security notes

- Firestore owner-only rules are in `firestore.flutter.rules`
- Input sanitization and validation are handled before writes hit Firestore
- App Check bootstrap code is in `lib/main.dart`
- Hardened hosting headers are configured in `firebase.flutter.json`
- Enable **Email/Password** auth and reCAPTCHA Enterprise in Firebase Console for full protection
- The public site key is configured in the app; the reCAPTCHA secret key is intentionally not stored in the client repo

## Run locally

1. Copy the example config and fill in your own Firebase values:

```bash
cd flutter_app
cp firebase.env.example.json firebase.env.json
```

2. Start the app with local defines:

```bash
flutter run -d chrome --dart-define-from-file=firebase.env.json
```

## Deploy

```bash
cd flutter_app
flutter build web --release --dart-define-from-file=firebase.env.json
firebase deploy --project myfluttercookbook --config firebase.flutter.json
```

## Mobile release build

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

