# LETS SIGNAL - Traffic Light Simulator

<div align="center">
  <img src="assets/images/icon.png" alt="LETS SIGNAL Icon" width="120" height="120">
  <br>
  <strong>Experience authentic traffic signals from around the world</strong>
  <br>
  <strong>Realistic traffic light simulator with multi-country support</strong>
</div>

## 📱 Application Overview

LETS SIGNAL is a Flutter-based traffic light simulator app for Android & iOS that lets you experience authentic traffic signals from United States, United Kingdom, Australia, and Japan.
It provides a realistic and educational experience through authentic sounds, animations, timing patterns, and multi-language support.

### 🎯 Key Features

- **Multi-Country Signal Support**: Authentic traffic signals from US, UK, Australia and Japan
- **Pedestrian Signals**: Realistic pedestrian crossing signals for each country
- **Cross-platform Support**: Android & iOS compatibility
- **Multi-language Support**: English, Japanese, Chinese
- **Google Mobile Ads**: Banner ads
- **Firebase Integration**: Analytics
- **Audio & Vibration Feedback**: Authentic signal sounds and haptic feedback
- **Premium Features**: Ad-free experience with RevenueCat integration
- **Customizable Settings**: Adjustable signal timing and audio preferences

## 🚀 Technology Stack

### Frameworks & Libraries

- **Flutter**: 3.47.0+
- **Dart**: 3.13.0+
- **Firebase**: Analytics
- **Google Mobile Ads**: Banner ads
- **RevenueCat**: In-app purchase management

### Core Features

- **Audio**: just_audio
- **Text-to-Speech**: flutter_tts, vendored at `packages/flutter_tts`
- **Vibration**: vibration
- **Localization**: flutter_localizations, intl
- **Device locale**: devicelocale
- **Environment Variables**: flutter_dotenv
- **State Management**: hooks_riverpod, flutter_hooks
- **Settings**: flutter_settings_screens, settings_ui
- **Storage**: shared_preferences

### flutter_tts is a local fork, not the pub.dev package

`pubspec.yaml` points `flutter_tts` at `packages/flutter_tts`, a fork of the published 4.2.5.
Upstream ships no Swift Package Manager manifest, and a single plugin without one makes Flutter fall back to CocoaPods for the whole iOS build.
The fork adds the SPM manifests and makes the Android build branch on `android.builtInKotlin` so AGP 9 compiles the Kotlin itself.
The Dart sources are unchanged, and the full list of differences is in the `pubspec.yaml` comment.

## 📋 Prerequisites

- Flutter 3.47.0+ (required by Android Gradle Plugin 9: earlier versions force the Kotlin Gradle Plugin onto modules that AGP 9 compiles itself)
- Dart 3.13.0+
- Android Studio / Xcode
- Firebase project (Analytics)
- RevenueCat account for the premium purchase, with the entitlements `signal_for_cars` and `no_ads` and the product `signal_upgrade_premium` (`lib/plan_provider.dart`, `lib/constant.dart`); the app grants premium only when both entitlements are active
- `firebase-tools` (`npm i -g firebase-tools`) and `flutterfire_cli` (`dart pub global activate flutterfire_cli`), then `firebase login`

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone https://github.com/fcb1899v/trafficlight_flutter.git
cd trafficlight_flutter
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configuration Files Setup

**Environment variables.** Copy `assets/.env_example` to `assets/.env` and fill in the values.
The template lists every key with what it is for, and is the one place that list is maintained.
`pubspec.yaml` declares `assets/.env`, so the file has to exist or the build fails.
Debug builds use Google's demo ad units and need no real ids, and the demo unit for an inline adaptive request is not the same id as the fixed-size one.

**Android signing, release only.** Copy `android/key.properties.example` to `android/key.properties` and fill it in.
Nothing in it ships inside the app, and the two passwords are real secrets: together with the keystore they let anyone publish an update Play accepts as coming from you.
Keep the keystore outside the repository and back both up.
A release built without this file falls back to the debug signing config, which produces an artifact Play rejects.

### 4. Firebase Configuration

1. Create a Firebase project and enable Analytics.
2. Run `flutterfire configure`.
   It writes `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` and `lib/firebase_options.dart`.
   **None of those are in git**, so run it after a fresh clone.
3. Run it before the first Android build: the Google Services Gradle plugin fails without the json.

### 5. Run the Application
```bash
flutter devices                 # take the id of the one you want
flutter run -d <device-id>
```

## 🎮 Application Structure

```
lib/
├── main.dart              # Application entry point
├── homepage.dart          # Main signal simulator screen
├── settings.dart          # Settings page
├── upgrade.dart           # Premium upgrade page
├── plan_provider.dart     # Premium state management
├── sound_manager.dart     # Audio management
├── admob_banner.dart      # Banner advertisement management
├── constant.dart          # Constant definitions
├── extension.dart         # Extension functions
├── firebase_options.dart  # Written by flutterfire configure, not in git
└── l10n/                  # Localization
    ├── app_en.arb
    ├── app_ja.arb
    ├── app_zh.arb
    ├── app_localizations.dart
    ├── app_localizations_en.dart
    ├── app_localizations_ja.dart
    └── app_localizations_zh.dart

packages/
└── flutter_tts/           # Local fork of flutter_tts 4.2.5

test/
└── settings_upgrade_entry_test.dart  # Settings upgrade entry, driven by the store price

assets/
├── images/                # Image resources
│   ├── pedestrian/       # Pedestrian signal images by country
│   │   ├── jp/          # Japanese pedestrian signals
│   │   ├── us/          # US pedestrian signals
│   │   ├── uk/          # UK pedestrian signals
│   │   └── au/          # Australian pedestrian signals
│   ├── traffic/         # Traffic signal images by country
│   │   ├── jp/          # Japanese traffic signals
│   │   ├── us/          # US traffic signals
│   │   ├── uk/          # UK traffic signals
│   │   └── au/          # Australian traffic signals
│   ├── icon.png         # App icon
│   ├── appIcon.png      # Adaptive icon foreground
│   ├── human.png        # Splash screen image
│   ├── forwardArrow.png # Forward arrow image
│   └── backArrow.png    # Back arrow image
├── audios/              # Audio files
│   ├── pon.mp3          # Button press sound
│   ├── sound_jp_new.mp3 # Japanese new signal sound
│   ├── sound_jp_old.mp3 # Japanese old signal sound
│   ├── sound_us_g.mp3   # US green signal sound
│   ├── sound_us_r.mp3   # US red signal sound
│   ├── sound_us_flash.mp3 # US flash signal sound
│   ├── sound_au_g.mp3   # Australian green signal sound
│   ├── sound_uk_g.mp3   # UK green signal sound
│   └── sound_none.mp3   # No sound option
└── fonts/               # Font files
    ├── NotoSansJP-Bold.ttf
    ├── NotoSansSC-Bold.ttf
    ├── Roboto-Bold.ttf
    ├── freetfb.ttf
    └── beon.ttf
```

## 📱 Supported Platforms

- **Android**: API 24+ (`flutter.minSdkVersion`), compiled and targeted at API 37
- **iOS**: iOS 15.0+ (`IPHONEOS_DEPLOYMENT_TARGET`)

## 🔧 Development

### Code Analysis
```bash
flutter analyze   # expected: No issues found!
```

### Run Tests
```bash
flutter test      # expected: All tests passed! (3 tests)
```

### Build
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

## 📄 License

This project is not open source.
The source is published so that it can be read, and all rights are reserved.
See [LICENSE](LICENSE) for what that permits.
Third-party components keep their own licenses, listed below.

## 🤝 Contributing

Issue reports are welcome.
Pull requests are not accepted, because the code is not licensed for redistribution.

## 📞 Support

If you have any problems or questions, please create an issue on GitHub.

## Licenses & Credits

This app uses the following third-party components:

- Flutter (BSD 3-Clause License)
- firebase_core, firebase_analytics (BSD 3-Clause License)
- google_mobile_ads (Apache License 2.0)
- Google Mobile Ads Android SDK (Android Software Development Kit License): `play-services-ads`, pulled in by google_mobile_ads
- Google Mobile Ads iOS SDK (proprietary Google binary; its CocoaPods spec declares only a Google copyright notice, with no open-source license): `Google-Mobile-Ads-SDK`, pulled in by google_mobile_ads
- User Messaging Platform, the consent SDK (Android Software Development Kit License): `com.google.android.ump:user-messaging-platform`, pulled in by google_mobile_ads
- User Messaging Platform on iOS (proprietary Google binary, declared the same way as the iOS ads SDK): `GoogleUserMessagingPlatform`, pulled in by `Google-Mobile-Ads-SDK`
- shared_preferences (BSD 3-Clause License)
- flutter_dotenv (MIT License)
- flutter_tts (MIT License)
- just_audio (MIT License), which bundles ExoPlayer on Android: `androidx.media3:media3-exoplayer` (Apache License 2.0)
- vibration (BSD 2-Clause License)
- hooks_riverpod, flutter_hooks (MIT License)
- webview_flutter, webview_flutter_android (BSD 3-Clause License)
- cupertino_icons (MIT License)
- flutter_launcher_icons (MIT License)
- flutter_native_splash (MIT License)
- intl (BSD 3-Clause License)
- flutter_localizations (BSD 3-Clause License)
- flutter_settings_screens (MIT License)
- settings_ui (Apache License 2.0)
- devicelocale (Apache License 2.0)
- purchases_flutter (MIT License)

For details of each license, please refer to [pub.dev](https://pub.dev/) or the LICENSE file in each repository.

