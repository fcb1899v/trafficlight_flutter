import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Signal Number
/// Total number of different signal configurations available in the app
const int signalNumber = 7;

/// App Name and Branding
/// Application title and logo image path
const String appTitle = "LETS SIGNAL";
const String appTitleImage = "assets/images/letsSignal.png";

/// App Check Configuration
/// Firebase App Check providers for security validation
/// Uses debug providers in debug mode, production providers in release mode
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.deviceCheck;

/// Time Configuration Constants
/// All time values are in seconds unless otherwise specified
const int maxTime = 30;          // Maximum allowed time for any signal phase (seconds)
const int minTime = 4;           // Minimum allowed time for any signal phase (seconds)
const int initialWaitTime = 8;   // Default red light duration (seconds)
const int initialGoTime = 8;     // Default green light duration (seconds)
const int initialFlashTime = 8;  // Default flashing light duration (seconds)
const int initialYellowTime = 3; // Default yellow light duration (seconds)
const int initialArrowTime = 3;  // Default arrow signal duration (seconds)
const int deltaFlash = 500;      // Flash interval for blinking signals (milliseconds)

/// Vibration Configuration
/// Haptic feedback settings for button interactions
const int vibTime = 200;         // Vibration duration (milliseconds)
const int vibAmp = 128;          // Vibration amplitude (0-255)

/// Color Definitions
/// Application color palette for consistent UI design
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color grayColor = Colors.grey;
const Color transpColor = Colors.transparent;

/// Custom Signal Colors
/// Traffic signal specific colors with RGB values
const Color signalGrayColor = Color.fromRGBO(35, 35, 35, 1);    // Dark gray for signal housing (#232323)
const Color transpGrayColor = Color.fromRGBO(200, 200, 200, 0.9); // Semi-transparent gray
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.9);    // Semi-transparent black
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.9); // Semi-transparent white

/// UI Element Colors
/// Colors for buttons, edges, and interface elements
const Color edgeColor1 = Color.fromRGBO(180, 180, 180, 1);      // Light gray for edges (#b4b4b4)
const Color edgeColor2 = Color.fromRGBO(230, 230, 230, 1);      // Lighter gray for highlights (#e6e6e6)

/// Traffic Signal Colors
/// Standard traffic light colors with custom RGB values
const Color darkYellowColor = Color.fromRGBO(190, 140, 60, 1);  // Dark yellow for countdown (#be8c3c)
const Color orangeColor = Color.fromRGBO(209, 130, 64, 1);      // Orange for warnings (#d18240)
const Color yellowColor = Color.fromRGBO(250, 210, 90, 1);      // Standard yellow (#fad25a)
const Color greenColor = Color.fromRGBO(87, 191, 163, 1);       // Standard green (#57BFA3)
const Color redColor = Color.fromRGBO(200, 77, 62, 1);          // Standard red (#C84D3E)

/// Transparent Signal Colors
/// Semi-transparent versions of signal colors for overlays
const Color transpYellowColor = Color.fromRGBO(250, 210, 90, 0.8);      // Transparent yellow (#fad25a)
const Color transpGreenColor = Color.fromRGBO(87, 191, 163, 0.8);       // Transparent green (#57BFA3)
const Color transpRedColor = Color.fromRGBO(200, 77, 62, 0.8);          // Transparent red (#C84D3E)

/// Background Color Array
/// Background colors for different signal configurations (0-6)
/// Each index corresponds to a specific country's signal style
const List<Color> backGroundColor = [
  transpGrayColor,   // US (index 0)
  transpGrayColor,   // US (index 1)
  transpGrayColor,   // UK (index 2)
  transpGrayColor,   // UK (index 3)
  transpWhiteColor,  // JP (index 4)
  transpWhiteColor,  // JP (index 5)
  transpGrayColor,   // AU (index 6)
];

/// Sound Configuration
/// Audio file paths and volume settings for sound effects
const String buttonSound = "audios/pon.mp3";        // Button press sound
const String audioFile = "audios/sound_";           // Base path for signal sounds
const String noneSound = "audios/sound_none.mp3";   // Silent sound file
const double musicVolume = 1;                       // Background music volume (0.0-1.0)
const double buttonVolume = 1;                      // Button sound volume (0.0-1.0)
const int audioPlayerNumber = 2;                    // Number of audio players for simultaneous sounds

/// Green Signal Sound Files
/// Audio files for green light signals by country (US, UK, JP, AU)
/// "none" indicates no sound for that signal
List<String> soundGreen = [
  "us_g",    // US green signal sound
  "none",    // US (no sound)
  "uk_g",    // UK green signal sound
  "none",    // UK (no sound)
  "jp_new",  // Japan new style green signal sound
  "jp_old",  // Japan old style green signal sound
  "us_g"     // AU green signal sound (uses US sound)
].map((t) => "$audioFile$t.mp3").toList();

/// Red Signal Sound Files
/// Audio files for red light signals by country
/// Most countries use "none" for red signals
List<String> soundRed = [
  "us_r",    // US red signal sound
  "none",    // US (no sound)
  "none",    // UK (no sound)
  "none",    // UK (no sound)
  "none",    // JP (no sound)
  "none",    // JP (no sound)
  "us_r"     // AU red signal sound (uses US sound)
].map((t) => "$audioFile$t.mp3").toList();

/// Image Asset Paths
/// Base directories for image assets organized by category
const String pedestrianAssets = "assets/images/pedestrian/";  // Pedestrian signal images
const String trafficAssets = "assets/images/traffic/";        // Traffic signal images

/// Navigation Arrow Images
/// Arrow images for navigation between signal types
const String forwardArrow = "assets/images/forwardArrow.png";  // Next signal arrow
const String backArrow = "assets/images/backArrow.png";        // Previous signal arrow

/// Country Flag Images
/// Flag images for each country's signal style
/// Order: US, US, UK, UK, JP, JP, AU
List<String> countryFlag = [
  "us", "us",  // US flags (2 variants)
  "uk", "uk",  // UK flags (2 variants)
  "jp", "jp",  // JP flags (2 variants)
  "au",        // AU flag (1 variant)
].map((t) => "$pedestrianAssets$t/flag_$t.png").toList();

/// Pedestrian Signal Images
/// Special images for pedestrian-specific signals
const String netImage = "${pedestrianAssets}us/net.png";  // US pedestrian crossing net image

/// Countdown Display Configuration
/// Settings for countdown timer display in Japanese signals
const List<Color> cdNumColor = [orangeColor, transpColor, yellowColor, transpColor, transpColor, transpColor, transpColor];  // Countdown number colors
const List<String> cdNumFont = ["dotFont", "", "freeTfb", "", "", "", ""];  // Countdown number fonts
const String jpCountDownOn = "${pedestrianAssets}jp/countdown_jp_on.png";   // Japanese countdown active image
const String jpCountDownOff = "${pedestrianAssets}jp/countdown_jp_off.png"; // Japanese countdown inactive image

/// Traffic Signal Images
/// Images for traffic signal flags and indicators
const String usStopFlag = "${trafficAssets}us/stop_flag.png";  // US stop flag image
const String usGoFlag = "${trafficAssets}us/go_flag.png";      // US go flag image
const int flagRotationTime = 1;                                 // Flag rotation animation duration (seconds)

/// Upgrade/In-App Purchase Configuration
/// Settings for premium upgrade functionality
const String premiumProduct = "signal_upgrade_premium";         // Product ID for premium upgrade
const double upgradeTableDividerWidth = 0;                      // Width of table dividers in upgrade screen
const double upgradeButtonElevation = 10;                       // Shadow elevation for upgrade buttons
const double upgradeButtonBorderWidth = 1.5;                    // Border width for upgrade buttons
const double upgradeButtonBorderRadius = 5;                     // Border radius for upgrade buttons

/// Settings Screen Configuration
/// UI settings for the settings screen
const double settingsTilePaddingSize = 20;                      // Padding size for settings tiles
const double settingsTileRadiusSize = 15;                       // Border radius for settings tiles

/// RevenueCat Configuration
/// API key selection based on platform (iOS/Android)
/// These keys should be replaced with actual RevenueCat API keys
String revenueCatApiKey = (Platform.isIOS || Platform.isMacOS) ?
  "REVENUE_CAT_IOS_API_KEY":      // iOS/macOS API key placeholder
  "REVENUE_CAT_ANDROID_API_KEY";  // Android API key placeholder
