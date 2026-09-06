# LETS SIGNAL - Traffic Light Simulator

<div align="center">
  <img src="assets/images/icon.png" alt="LETS SIGNAL Icon" width="120" height="120">
  <br>
  <strong>Experience authentic traffic signals from around the world</strong>
  <br>
  <strong>Realistic traffic light simulator with multi-country support</strong>
</div>

## 📱 Application Overview

LETS SIGNAL is a Flutter-based traffic light simulator app for Android & iOS that lets you experience authentic traffic signals from United States, United Kingdom, Australia, and Japan. It provides a realistic and educational experience through authentic sounds, animations, timing patterns, and multi-language support.

### 🎯 Key Features

- **Multi-Country Signal Support**: Authentic traffic signals from US, UK, Australia and Japan.
- **Pedestrian Signals**: Realistic pedestrian crossing signals for each country
- **Cross-platform Support**: Android & iOS compatibility
- **Multi-language Support**: English, Japanese, Chinese
- **Google Mobile Ads**: Banner ads integration
- **Firebase Integration**: Analytics, App Check
- **Audio & Vibration Feedback**: Authentic signal sounds and haptic feedback
- **Premium Features**: Ad-free experience with RevenueCat integration
- **Customizable Settings**: Adjustable signal timing and audio preferences

## 🚀 Technology Stack

### Frameworks & Libraries
- **Flutter**: 3.3.0+
- **Dart**: 2.18.0+
- **Firebase**: Analytics, App Check
- **Google Mobile Ads**: Advertisement display
- **RevenueCat**: In-app purchase management

### Core Features
- **Audio**: just_audio
- **Text-to-Speech**: flutter_tts
- **Vibration**: vibration
- **Localization**: flutter_localizations
- **Environment Variables**: flutter_dotenv
- **App Tracking Transparency**: app_tracking_transparency
- **WebView**: webview_flutter
- **State Management**: hooks_riverpod, flutter_hooks
- **Settings**: flutter_settings_screens
- **Storage**: shared_preferences

## 📋 Prerequisites

- Flutter 3.47.0+ (required by Android Gradle Plugin 9: earlier versions
  force the Kotlin Gradle Plugin onto modules that AGP 9 compiles itself)
- Dart 3.13.0+
- Android Studio / Xcode
- Firebase (App Check, Analytics)
- RevenueCat (for premium features)

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone https://github.com/fcb1899v/trafficlight_flutter.git
cd signalbutton
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Variables Setup
Create `assets/.env` file and configure required environment variables:
```env
REVENUE_CAT_IOS_API_KEY="your-ios-api-key"
REVENUE_CAT_ANDROID_API_KEY="your-android-api-key"
```

### 4. Firebase Configuration (Optional)
If using Firebase:
1. Create a Firebase project
2. Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Both files are tracked here. The Gradle plugin fails the Android build
   without the json, and the Xcode project lists the plist in its Resources
   phase, so excluding them only broke fresh clones. They carry the same
   identifiers as `lib/firebase_options.dart`, which ship inside the app.
   Real secrets stay out: the keystore, `key.properties` and `.env`

### 5. Run the Application
```bash
# Android
flutter run

# iOS (Swift Package Manager: there is no Podfile to install)
flutter run
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
├── firebase_options.dart  # Firebase configuration
└── l10n/                  # Localization
    ├── app_en.arb
    ├── app_ja.arb
    └── app_zh.arb

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
│   ├── appIcon.png      # App icon for adaptive icons
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
├── fonts/               # Font files
│   ├── NotoSansJP-Bold.ttf
│   ├── NotoSansSC-Bold.ttf
│   ├── Roboto-Bold.ttf
│   ├── freetfb.ttf
│   └── beon.ttf
└── .env                 # Environment variables (not in git)
```

## 🎨 Customization

### Signal Timing
- **Wait Time**: Duration of red light
- **Go Time**: Duration of green light
- **Flash Time**: Duration of flashing signals
- **Yellow Time**: Duration of yellow/amber light
- **Arrow Time**: Duration of arrow signals

### Audio Settings
- Enable/disable sound effects
- Adjust volume levels
- Customize vibration feedback
- Text-to-speech announcements

### Country-Specific Features
- **Japan**: Traditional and modern signal patterns with countdown displays
- **United States**: Standard traffic signals with flashing yellow arrows
- **United Kingdom**: UK-style traffic lights with amber sequences
- **Australia**: Australian traffic signal patterns

## 📱 Supported Platforms

- **Android**: API 23+
- **iOS**: iOS 14.0+
- **Web**: Coming soon

## 🔧 Development

### Code Analysis
```bash
flutter analyze
```

### Run Tests

There are none. The `flutter create` counter test was removed on 2026-09-02
because it asserted on a widget this app does not have and could only ever fail,
which made a red `flutter test` indistinguishable from a real failure.

`flutter analyze` is the check that runs clean and is expected to stay that way.

```bash
flutter analyze   # expected: No issues found!
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

## 🔒 Security

This project includes security measures to protect sensitive information:
- Environment variables for API keys
- Firebase configuration files are excluded from version control
- RevenueCat API keys are stored in environment files
- Keystore files are properly excluded

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Pull requests and issue reports are welcome.

## 📞 Support

If you have any problems or questions, please create an issue on GitHub.

## 🚀 Getting Started

For new developers:
1. Follow the setup instructions above
2. Check the application structure
3. Review the customization options
4. Start with the main.dart file to understand the app flow

---

<div align="center">
  <strong>LETS SIGNAL</strong> - Experience authentic traffic signals from around the world!
</div>

## Licenses & Credits

This app uses the following open-source libraries:

- Flutter (BSD 3-Clause License)
- firebase_core, firebase_analytics, firebase_app_check (Apache License 2.0)
- google_mobile_ads (Apache License 2.0)
- shared_preferences (BSD 3-Clause License)
- flutter_dotenv (MIT License)
- flutter_tts (BSD 3-Clause License)
- just_audio (MIT License)
- vibration (MIT License)
- hooks_riverpod, flutter_hooks (MIT License)
- webview_flutter (BSD 3-Clause License)
- cupertino_icons (MIT License)
- flutter_launcher_icons (MIT License)
- flutter_native_splash (MIT License)
- intl (BSD 3-Clause License)
- flutter_localizations (BSD 3-Clause License)
- flutter_settings_screens (MIT License)
- settings_ui (MIT License)
- app_tracking_transparency (MIT License)
- devicelocale (MIT License)
- purchases_flutter (MIT License)

For details of each license, please refer to [pub.dev](https://pub.dev/) or the LICENSE file in each repository.

---

**Note**: This app is for educational and entertainment purposes. Please do not use it while driving or in situations where it could be distracting or dangerous.
