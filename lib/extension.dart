import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:purchases_flutter/errors.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'homepage.dart';
import 'settings.dart';
import 'upgrade.dart';
import 'constant.dart';

part 'l10n_extension.dart';
part 'size_extension.dart';

/// Get default country counter based on device locale
/// Shared by HomePage (signal style) and UpgradePage (localized buy button)
Future<int> getCountryCounter() async {
  final locale = await Devicelocale.currentLocale ?? "en-US";
  final countryCode = locale.substring(3, 5);
  final counter = countryCode.getDefaultCounter();
  "Locale: $locale, counter: $counter".debugPrint();
  return counter;
}

/// Extension on BuildContext for navigation
/// (localization -> L10nContextExt in l10n_extension.dart)
/// (sizing -> SizeExt in size_extension.dart)
extension ContextExt on BuildContext {
  /// Navigation Methods
  /// Convenient navigation to different app screens
  void pushHomePage() =>
      Navigator.pushReplacement(this, MaterialPageRoute(builder: (BuildContext context) =>  const HomePage()));
  void pushSettingsPage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const SettingsPage()));
  /// Fades in over the current screen. The back "<" itself is unchanged (see test/upgrade_back_test.dart)
  Future<void> pushUpgradePage({UpgradeSource source = UpgradeSource.settings}) =>
      Navigator.push(this, PageRouteBuilder(
        pageBuilder: (_, _, _) => UpgradePage(source: source),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ));
}


/// Extension on String for utility operations and settings management
/// Provides methods for debug printing, settings access, and image path generation
extension StringExt on String {

  /// Debug Printing
  /// Prints the string only in debug mode
  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  /// Settings access with default values; the string is the key prefix
  /// (e.g. "wait" becomes "key_wait")
  int getSettingsValueInt(int defaultValue) =>
    Settings.getValue<int>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  bool getSettingsValueBool(bool defaultValue) =>
      Settings.getValue<bool>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  String getSettingsValueString(String defaultValue) =>
      Settings.getValue<String>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  /// Country Code to Signal Index Mapping
  /// Returns the default signal configuration index for each country
  int getDefaultCounter() =>
      (this == "GB") ? 3:  // UK signals
      (this == "JP") ? 5:  // Japan signals
      (this == "AU") ? 6:  // Australia signals
      0;                   // US signals (default)

  /// Signal Image Path Generation
  /// Methods for generating image paths for different signal states and countries
  
  /// Button frame images per signal state (wait, red, green, off), indexed by style (0-6)
  List<String> buttonFrame() => [
    "us/frame_us_new",                                                    // US new style
    "us/frame_us_old",                                                    // US old style
    "uk/frame_uk_new_${(this == "green") ? "g": (this == "off") ? "off": "r"}",  // UK new style
    "uk/frame_uk_old_${(this == "wait") ? "on": "off"}",                  // UK old style
    "jp/frame_jp_new",                                                    // Japan new style
    "jp/frame_jp_old",                                                    // Japan old style
    "au/frame_au_${(this == "wait") ? "on" : "off"}",                     // Australia style
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Push button images for on/off states, indexed by style (0-6)
  List<String> pushButtonImage() => [
    "us/button_us_new_${(this == 'on') ? 'on': 'off'}",  // US new style
    "us/button_us_old",                                  // US old style
    "uk/button_uk_new_${(this == 'on') ? 'on': 'off'}",  // UK new style
    "uk/button_uk_old",                                  // UK old style
    "jp/button_jp_new",                                  // Japan new style
    "jp/button_jp_old",                                  // Japan old style
    "au/button_au",                                      // Australia style
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Pedestrian signal images per state (flash, red, green, off), indexed by style (0-6)
  List<String> pedestrianSignal() => [
    "us/signal_us_new2_${(this == 'green') ? 'g': (this == 'off') ? 'off': 'r'}",  // US new style
    "us/signal_us_old_${(this == 'green') ? 'g': (this == 'off') ? 'off': 'r'}",    // US old style
    "uk/signal_uk_new_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // UK new style
    "uk/signal_uk_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // UK old style
    "jp/signal_jp_new_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Japan new style
    "jp/signal_jp_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Japan old style
    "uk/signal_uk_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Australia (uses UK old)
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Traffic signal images per state (yellow, red, green, off, arrow), indexed by style (0-6)
  List<String> trafficSignal() => [
    "us/signal_us_new_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",  // US new style
    "us/signal_us_old_${(this == "yellow") ? "y": (this == "red" || this == "arrow") ? "r": "g"}",  // US old style
    "uk/signal_uk_new_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",  // UK new style
    "uk/signal_uk_old_${(this == "red" || this == "arrow") ? "r": "g"}",                            // UK old style
    "jp/signal_jp_new_${(this == "green") ? "g": (this == "red") ? "r": (this == "arrow") ? "arrow": "y"}",  // Japan new style
    "jp/signal_jp_old_${(this == "green") ? "g": (this == "red") ? "r": (this == "arrow") ? "arrow": "y"}",  // Japan old style
    "au/signal_au_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",      // Australia style
  ].map((t) => "$trafficAssets$t.png").toList();
}

/// Extension on int for countdown and number operations
/// Provides methods for countdown display and number formatting
extension IntExt on int {

  /// Countdown meter segments as booleans, from remaining time as a share of green time
  List<bool> countMeterColor(int greenTime) =>
      (this / greenTime > 0.875) ? [true, true, true, true, true, true, true, true]:      // 87.5% - 100%
      (this / greenTime > 0.750) ? [false, true, true, true, true, true, true, true]:     // 75% - 87.5%
      (this / greenTime > 0.625) ? [false, false, true, true, true, true, true, true]:    // 62.5% - 75%
      (this / greenTime > 0.500) ? [false, false, false, true, true, true, true, true]:   // 50% - 62.5%
      (this / greenTime > 0.375) ? [false, false, false, false, true, true, true, true]:  // 37.5% - 50%
      (this / greenTime > 0.250) ? [false, false, false, false, false, true, true, true]: // 25% - 37.5%
      (this / greenTime > 0.125) ? [false, false, false, false, false, false, true, true]: // 12.5% - 25%
      (this / greenTime > 0) ? [false, false, false, false, false, false, false, true]:    // 0% - 12.5%
      [false, false, false, false, false, false, false, false];                            // 0% or less

  /// Utility Methods for Countdown Display
  /// Helper methods for countdown number formatting and display
  double isOne() => (this == 1) ? this * 1.0: 0;  // Returns 1.0 if value is 1, otherwise 0
  
  /// Countdown Number Extraction
  /// Extracts tens and ones digits for countdown display
  int cdTenNumber(bool isFlash) => (this > 9 && isFlash) ? this ~/ 10: 8;   // Tens digit or 8 if not flashing
  int cdFirstNumber(bool isFlash) => (isFlash) ? this % 10: 8;              // Ones digit or 8 if not flashing
  
  /// Countdown Number String Conversion
  /// Converts countdown numbers to strings for display
  String cdTenNumberString(bool isFlash) => "${cdTenNumber(isFlash)}";
  String cdFirstNumberString(bool isFlash) => "${cdFirstNumber(isFlash)}";
  
  /// Countdown Number Color Selection
  /// Returns appropriate color for countdown numbers based on flash state
  Color cdTenColor(Color color, bool isFlash,) => (this > 9 && isFlash) ? color: signalGrayColor;
  Color cdFirstColor(Color color, bool isFlash) => (isFlash) ? color: signalGrayColor;
}
