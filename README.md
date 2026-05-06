# Study Tracker

Flutter app (Android only in this repo).

## Requirements

- Flutter SDK (stable channel)
- Android SDK + platform tools (via Android Studio or command-line tools)
- JDK 17 or 21 (required by Gradle)

## Setup (per machine)

1. Install Flutter and Android SDK, then verify:

```bash
flutter --version
flutter doctor
```

2. From the project root:

```bash
flutter pub get
```

3. Ensure Firebase config exists at `android/app/google-services.json`.
	 - If you do not have access to the original Firebase project, create your own Firebase Android app and place its `google-services.json` there.

## Run the app

```bash
flutter run
```

## Build a release APK

```bash
flutter build apk
```

## Java / Gradle notes

Gradle requires **JDK 17 or 21**. If builds fail with JDK 25 or an invalid Java home:

- Prefer setting `JAVA_HOME` to JDK 17/21.
- Or set `org.gradle.java.home` in your **user** Gradle properties file:
	- Windows: `%USERPROFILE%\.gradle\gradle.properties`
	- macOS/Linux: `~/.gradle/gradle.properties`

Example:

```properties
org.gradle.java.home=C:/Program Files/Eclipse Adoptium/jdk-21.0.11.10-hotspot
```

## Generated files (do not edit)

These files are generated and should not be edited by hand:

- `lib/models/*.g.dart`
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
- `.flutter-plugins-dependencies`
- `.dart_tool/`
- `android/local.properties` (per-machine SDK paths)

To regenerate Dart code after model changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

- Kotlin compile daemon connection warnings are usually safe. Gradle falls back to in-process compilation and the build still succeeds.
- If `android/local.properties` is missing, Flutter or Android Studio will recreate it automatically.