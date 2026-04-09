# CSCI322 Cookbook Flutter Project

A Flutter-based cookbook app for CSCI 322, rebuilt around Firebase and TheMealDB.

## Submission links

- **GitHub:** `https://github.com/ethCS/cookbook_flutter`
- **Hosted site:** `https://myfluttercookbook.web.app`
- **Best viewed on:** **mobile or desktop** (responsive layout supported)

## Requirement checklist

- ✅ **Use Flutter** — main project lives in `flutter_app/`
- ✅ **Be hosted** — deployed on Firebase Hosting
- ✅ **Hit at least one API** — recipe data comes from **TheMealDB**
- ✅ **Hit a database** — favorites and custom recipes are stored in **Cloud Firestore**
- ✅ **Reasonable security** — Firestore rules, App Check, CSP headers, and input sanitization are included
- ✅ **Look like a complete project** — themed UI, responsive layout, auth, search, favorites, and custom recipe management
- ✅ **Include planned pages and make them accessible** — Home, Search, Recipe Details, Favorites, My Recipes, and Sign In are reachable through the app UI
- ✅ **Publicly available** — source is hosted on GitHub

## App pages

- **Home** — featured meals and categories
- **Search** — query recipes from TheMealDB API
- **Recipe Details** — ingredients and instructions for each meal
- **Favorites** — saved meals per signed-in user
- **My Recipes** — user-created recipes stored in Firestore
- **Auth** — sign in / sign out flow using Firebase Authentication

For setup and deployment details, see `flutter_app/README.md`.

