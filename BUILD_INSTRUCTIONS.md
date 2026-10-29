# Personal Life RPG - Build Instructions

## Overview
This document describes how to build and install the Personal Life RPG Android application.

## Prerequisites
- Flutter SDK 3.12+ (stable channel)
- Android SDK with API level 34
- Java 17 JDK
- Git

## Keystore Information
The release APK is signed with the following keystore:
- **Keystore file**: `release.keystore` (in project root)
- **Alias**: `rpg-key`
- **Store Password**: `rpgpassword`
- **Key Password**: `rpgpassword`
- **Validity**: 10,000 days
- **Key Algorithm**: RSA 2048-bit
- **DN**: CN=RPG, OU=Dev, O=RPG, L=City, S=State, C=US

## Building the Release APK

### Option 1: Using Flutter CLI (Recommended)
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release --no-tree-shake-icons
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Option 2: Using Gradle directly
```bash
cd android
./gradlew assembleRelease
```

The APK will be generated at:
```
android/app/build/outputs/apk/release/app-release.apk
```

## Installing the APK

### On Android Device (Direct Install)
1. Enable "Install unknown apps" for your file manager or browser
2. Transfer `app-release.apk` to your device
3. Open the APK file and follow installation prompts

### Via ADB (Developer Mode)
```bash
# Connect device via USB with USB debugging enabled
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via Android Studio
1. Open project in Android Studio
2. Build → Build Bundle(s) / APK(s) → Build APK(s)
3. Locate APK in `build/app/outputs/flutter-apk/`

## GitHub Actions CI/CD
The repository includes a GitHub Actions workflow (`.github/workflows/create_entity.yml`) that:
1. Triggers on `repository_dispatch` or `workflow_dispatch`
2. Runs Python audit script to validate entity creation
3. Commits valid entities to JSON data files
4. Updates status file (`.rpg_status.json`)

### Required GitHub Secrets
- `GITHUB_TOKEN` (automatically provided)

### Triggering Workflow Manually
```bash
gh workflow run create_entity.yml \
  -f entity_type=branch \
  -f entity_id=my_new_branch \
  -f payload='{"id":"my_new_branch","name":"My Branch","description":"Test branch","accent_color":-16711681,"icon_code_point":59606,"icon_font_family":"MaterialIcons","level":1,"current_xp":0,"xp_to_next_level":5000,"weight":1.0,"is_active":true,"sort_order":4,"created_at":"2024-01-01T00:00:00.000Z","updated_at":"2024-01-01T00:00:00.000Z","activities":[],"metadata":{}}'
```

## Configuration

### GitHub Sync Setup
1. Open the app
2. Navigate to Config tab (bottom navigation)
3. Enter your GitHub Personal Access Token (PAT) with `repo` scope
4. Enter repository in format: `owner/repo` (e.g., `esrimova/RPG`)
5. Tap "SAVE CONFIG"

The PAT is stored securely using `flutter_secure_storage`.

## Project Structure
```
├── lib/
│   ├── src/
│   │   ├── core/           # Theme, constants, utilities
│   │   ├── data/           # Data layer (repositories, datasources)
│   │   ├── domain/         # Domain layer (entities, repositories, usecases)
│   │   └── presentation/   # UI layer (pages, widgets, providers)
│   └── main.dart
├── android/                # Android-specific configuration
├── .github/
│   ├── workflows/          # GitHub Actions workflows
│   └── scripts/            # Python audit scripts
├── branches.json           # Branch data
├── activities.json         # Activity data
├── records.json            # Record data
├── release.keystore        # Release signing keystore
└── BUILD_INSTRUCTIONS.md   # This file
```

## Troubleshooting

### Build Fails with "Missing storeFile"
Ensure `release.keystore` exists in project root and `android/app/key.properties` has correct path:
```
storeFile=../../release.keystore
```

### Build Fails with "Non-constant IconData"
Use `--no-tree-shake-icons` flag:
```bash
flutter build apk --release --no-tree-shake-icons
```

### GitHub Sync Fails
1. Verify PAT has `repo` scope
2. Check repository format: `owner/repo`
3. Ensure workflow file exists at `.github/workflows/create_entity.yml`

## Version Information
- **Version**: 1.0.0+1
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Architecture**: arm64-v8a, armeabi-v7a

## Security Notes
- Never commit `release.keystore` or `key.properties` to version control
- Never hardcode GitHub PAT in source code
- The PAT is encrypted using platform-specific secure storage (Keystore on Android)

## Support
For issues or questions, check the GitHub repository: https://github.com/esrimova/RPG