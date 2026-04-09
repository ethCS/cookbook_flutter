# CSCI322 Cookbook Flutter Project

This repository contains my cookbook project for CSCI 322. The app was rebuilt in Flutter and uses Firebase for auth and data storage, with recipe content coming from TheMealDB.

## Project links

- **GitHub:** `https://github.com/ethCS/cookbook_flutter`
- **Live site:** `https://myfluttercookbook.web.app`
- **Responsive on:** mobile and desktop

## About the app

The goal of the project was to make something that feels like a real recipe app instead of a simple class demo. Users can browse meals, search for recipes, save favorites, and add their own recipes after signing in.

## Main pages

- **Home** for featured meals and categories
- **Search** for finding recipes from TheMealDB
- **Recipe Details** for ingredients and cooking steps
- **Favorites** for saved meals tied to each user
- **My Recipes** for custom recipes stored in Firestore
- **Auth** for sign in and sign out

## Tech used

- **Flutter** for the app itself
- **Firebase Hosting** for deployment
- **Firebase Authentication** for user sign-in
- **Cloud Firestore** for favorites and custom recipes
- **TheMealDB API** for recipe data

If you want the setup and deployment steps, check `flutter_app/README.md`.

