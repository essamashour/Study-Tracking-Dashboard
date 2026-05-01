# Study Tracking Dashboard

A modern Flutter app for managing courses, tasks, and progress.
Authentication uses Firebase Auth, while all user data is stored locally with Hive.

## Features
- Firebase email/password authentication
- Local data storage with Hive (offline-first)
- Courses, tasks, and progress tracking
- Material 3 UI with Arabic/English localization
- Light/Dark theme toggle

## Tech Stack
- Flutter (Dart)
- Firebase Auth
- Hive + Hive Flutter
- Google Fonts
- Material 3

## Project Structure
- lib/screens: UI screens (auth, dashboard, courses, tasks, progress)
- lib/widgets: dialogs and reusable widgets
- lib/models: Hive models and adapters
- lib/services: auth + local storage services
- lib/utils: helper utilities

## Getting Started
### 1) Install dependencies
```bash
flutter pub get
```

### 2) Firebase setup (Auth only)
- Add android/app/google-services.json
- Add ios/Runner/GoogleService-Info.plist

### 3) Run
```bash
flutter run
```

## Build (Android)
```bash
flutter build apk
```

## Notes
- User data is stored locally in Hive.
- Firebase is used only for authentication.

## License
MIT
