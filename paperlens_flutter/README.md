# PaperLens

PaperLens is a Flutter app for research-paper analysis and research workflow support. It connects to the PaperLens FastAPI backend and uses Clerk for mobile authentication.

## What the app does

PaperLens includes these signed-in features:

- Dashboard overview
- Paper analyzer
- Experiment planner
- Idea/problem generator
- Gap detection
- Dataset and benchmark finder
- Citation intelligence
- Saved items and settings

The app is designed for Android mobile use and ships with a professional landing page plus Clerk-based sign-in.

## Authentication flow

The app uses Clerk for authentication.

- The landing page shows a Get Started action.
- Tapping it opens a full-screen Clerk sign-in page.
- Google sign-in and email sign-in are handled by Clerk.
- After sign-in, the app loads the main dashboard and syncs the Clerk session token.

## Environment variables

The app reads configuration from the local `.env` file.

Current values:

```env
API_BASE_URL=https://paperlens-ai.onrender.com
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
```

Notes:

- `API_BASE_URL` points to the backend API.
- `CLERK_PUBLISHABLE_KEY` is a public Clerk publishable key, but it should still stay in `.env` so it is not hardcoded in source files.
- Do not place private secrets, service account keys, or admin tokens in the Flutter client.

## Project structure

- `lib/main.dart` - app startup, theme handling, and Clerk initialization
- `lib/screens/auth_landing_page.dart` - landing page and Clerk sign-in entry point
- `lib/screens/migration_step_one_page.dart` - signed-in shell and API/token orchestration
- `lib/screens/post_signin/feature_sections/` - dashboard, analyzer, planner, ideas, gaps, datasets, citation, and settings views
- `lib/services/` - API client, storage, parsing, retrieval, and related helpers
- `android/` - Android native project and release build config

## Prerequisites

- Flutter SDK
- Dart SDK that matches the project constraints
- Android Studio or Android command-line tools
- A physical Android phone or emulator
- Access to the PaperLens backend

## Local setup

1. Clone or open the repository.
2. Make sure `.env` exists in the Flutter project root.
3. Confirm the backend URL and Clerk publishable key are set correctly.
4. Install dependencies:

```bash
flutter pub get
```

5. Run the app:

```bash
flutter run
```

## Running the backend

The app expects the backend to be available at the URL in `API_BASE_URL`.

Example local backend run:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

If you are using a phone on the same Wi-Fi network as your PC, set `API_BASE_URL` to your PC's local IP, for example:

```env
API_BASE_URL=http://192.168.1.8:8000
```

## Android requirements

The Android app includes the required network permissions for auth and API access:

- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`

The app label is set to `PaperLens`.

## Build a release APK

To create a shareable APK:

```bash
flutter build apk --release
```

The release APK is generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

A share-friendly copy can also be created manually if needed:

```text
PaperLens-release.apk
```

## Release notes

- The first-login flow opens Clerk in a full-screen page for better reliability on smaller phones.
- Session tokens are refreshed and reused across the signed-in sections.
- Android release builds are configured for a stable release output.

## Troubleshooting

### Login page does not open

- Confirm the app is loading the landing page from `lib/main.dart`.
- Check that `.env` contains `CLERK_PUBLISHABLE_KEY`.
- Make sure the device has network access.

### Google sign-in does nothing

- Confirm the device has internet access.
- Make sure Clerk sign-in is loading in the full-screen auth page.
- Verify the Clerk instance allows Google sign-in.
- If the app is side-loaded, test with a fresh install after clearing app data.

### Backend requests fail

- Verify `API_BASE_URL` is reachable from the phone.
- Make sure the backend is running and the device is on the same network if using a local IP.
- Refresh the Clerk session token from the app settings if the token expires.

### APK build fails

- Run `flutter clean`
- Then run `flutter pub get`
- Then rebuild with `flutter build apk --release`

## Documentation status

This README reflects the current PaperLens Flutter app state and is intended to be the main project documentation for GitHub.
