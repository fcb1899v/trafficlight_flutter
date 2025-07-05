import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:purchases_flutter/errors.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'homepage.dart';
import 'settings.dart';
import 'upgrade.dart';
import 'constant.dart';

/// Extension on BuildContext for common UI operations and localization
/// Provides convenient methods for accessing device information, navigation, and localized strings
extension ContextExt on BuildContext {

  /// Locale and Language Configuration
  /// Methods for accessing device locale and language-specific settings
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;
  
  /// Returns appropriate font family based on language
  /// Japanese: Noto Sans JP, Chinese: Noto Sans SC, Others: Beon
  String font() =>
    (lang() == "ja") ? "notoJP":
    (lang() == "zh") ? "notoSC":
    "beon";

  /// Device Size and Layout Information
  /// Methods for accessing screen dimensions and safe areas
  // Common size methods
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  
  // Settings screen specific sizing
  double settingsSidePadding() => width() < 600 ? 10: width() / 2 - 290;
  
  // AdMob banner sizing based on screen height
  double admobHeight() => (height() < 750) ? 50: (height() < 1000) ? 50 + (height() - 750) / 5: 100;
  double admobWidth() => width();

  /// Localization Methods
  /// Convenient access to localized strings throughout the app
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String settingsTitle() => AppLocalizations.of(this)!.settingsTitle;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String plan() => AppLocalizations.of(this)!.plan;
  String free() => AppLocalizations.of(this)!.free;
  String premium() => AppLocalizations.of(this)!.premium;
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String toUpgrade() => AppLocalizations.of(this)!.toUpgrade;
  String restore() => AppLocalizations.of(this)!.restore;
  String toRestore() => AppLocalizations.of(this)!.toRestore;
  
  /// Purchase and Restore Messages
  /// Success and error messages for in-app purchase operations
  String successPurchase() => AppLocalizations.of(this)!.successPurchase;
  String successRestore() => AppLocalizations.of(this)!.successRestore;
  String successPurchaseMessage(bool isRestore) => isRestore ? successRestore(): successPurchase();
  String errorPurchase() => AppLocalizations.of(this)!.errorPurchase;
  String errorRestore() => AppLocalizations.of(this)!.errorRestore;
  String errorPurchaseTitle(bool isRestore) => isRestore ? errorRestore(): errorPurchase();
  
  /// Error and Status Messages
  /// Various error messages and status indicators
  String readError() => AppLocalizations.of(this)!.readError;
  String failPurchase() => AppLocalizations.of(this)!.failPurchase;
  String failRestore() => AppLocalizations.of(this)!.failRestore;
  String failPurchaseMessage(bool isRestore) => isRestore ? failRestore(): failPurchase();
  String purchaseCancelledMessage() => AppLocalizations.of(this)!.purchaseCancelledMessage;
  String paymentPendingMessage() => AppLocalizations.of(this)!.paymentPendingMessage;
  String purchaseInvalidMessage() => AppLocalizations.of(this)!.purchaseInvalidMessage;
  String purchaseNotAllowedMessage() => AppLocalizations.of(this)!.purchaseNotAllowedMessage;
  String networkErrorMessage() => AppLocalizations.of(this)!.networkErrorMessage;
  
  /// Purchase Error Message Handler
  /// Returns appropriate error message based on RevenueCat error code
  String purchaseErrorMessage(PurchasesErrorCode? errorCode, bool isRestore) =>
    (errorCode == null) ? failPurchaseMessage(isRestore):
    (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
    (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage():
    (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage():
    (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage():
    (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage():
    failPurchaseMessage(isRestore);
  
  /// UI Element Labels
  /// Localized strings for various UI elements
  String loading() => AppLocalizations.of(this)!.loading;
  String loadingError() => AppLocalizations.of(this)!.loadingError;
  String pushButton() => AppLocalizations.of(this)!.pushButton;
  String pedestrianSignal() => AppLocalizations.of(this)!.pedestrianSignal;
  String carSignal() => AppLocalizations.of(this)!.carSignal;
  String noAds() => AppLocalizations.of(this)!.noAds;
  String timeSettings() => AppLocalizations.of(this)!.timeSettings;
  String timeUnit() => AppLocalizations.of(this)!.timeUnit;
  String waitTime() => AppLocalizations.of(this)!.waitTime;
  String goTime() => AppLocalizations.of(this)!.goTime;
  String flashTime() => AppLocalizations.of(this)!.flashTime;
  String soundSettings() => AppLocalizations.of(this)!.soundSettings;
  String crosswalkSound() => AppLocalizations.of(this)!.crosswalkSound;
  String toSettings() => AppLocalizations.of(this)!.toSettings;
  String toOn() => AppLocalizations.of(this)!.toOn;
  String toOff() => AppLocalizations.of(this)!.toOff;
  String toNew() => AppLocalizations.of(this)!.toNew;
  String toOld() => AppLocalizations.of(this)!.toOld;
  String confirmed() => AppLocalizations.of(this)!.confirmed;
  
  /// Utility Methods
  /// Helper methods for common operations
  String oldOrNew(bool isNew) => (isNew) ? toOld(): toNew();
  String settingsPremiumTitle(String premiumPrice, bool isReadError) =>
      (premiumPrice != "") ? premiumPlan():
      (isReadError) ? readError(): loading();

  /// Navigation Methods
  /// Convenient navigation to different app screens
  void pushHomePage() =>
      Navigator.pushReplacement(this, MaterialPageRoute(builder: (BuildContext context) =>  const HomePage()));
  void pushSettingsPage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const SettingsPage()));
  void pushUpgradePage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const UpgradePage()));

  /// Common UI Sizing
  /// Responsive sizing for common UI elements based on screen height
  double appBarHeight() => height() * 0.06;
  double appBarFontSize() => height() * (font() == "beon" ? 0.036: 0.03);
  double appBarIconSize() => height() * 0.036;

  /// Signal Display Sizing
  /// Responsive sizing for traffic signal elements
  double flagSize() => height() * 0.33;
  double frameHeight() => height() * 0.40;
  double signalHeight() => height() * 0.35;
  double usOldSignalFlagHeight() => height() * 0.18;
  
  /// Countdown Meter Sizing
  /// Sizing for countdown display elements
  double countMeterTopSpace() => height() * 0.035;
  double countMeterCenterSpace() => height() * 0.08;
  double countDownRightPadding() => height() * 0.003;
  double countMeterWidth() => height() * 0.012;
  double countMeterHeight() => height() * 0.01;
  double countMeterSpace() => height() * 0.0024;
  
  /// Floating Action Button Sizing
  /// Sizing for floating action buttons and related elements
  double floatingButtonSize() => height() * 0.07;
  double floatingImageSize() => height() * 0.02;
  double floatingIconSize() => height() * 0.03;
  double floatingMarginBottom() => admobHeight() + floatingButtonSize() / 2;

  /// Signal-Specific Layout Arrays
  /// Arrays containing layout parameters for each signal configuration (0-6)
  /// Each array index corresponds to a specific country's signal style
  List<double> buttonHeight() => [0.13, 0.11, 0.05, 0.04, 0.115, 0.08, 0.15].map((r) => height() * r).toList();
  List<double> buttonTopMargin() => [0.225, 0.29, 0.328, 0.325, 0.143, 0.17, 0.22].map((r) => height() * r).toList();
  List<double> frameTopPadding() => [0, 0, 0, 0, 0.01, 0.02, 0].map((r) => height() * r).toList();
  List<double> frameBottomPadding() => [0, 0.08, 0, 0, 0.01, 0.02, 0].map((r) => height() * r).toList();
  List<double> labelTopMargin() => [0, 0, 0, 0, 0.085, 0.10, 0].map((r) => height() * r).toList();
  List<double> labelMiddleMargin() => [0, 0, 0, 0, 0.14, 0.135, 0].map((r) => height() * r).toList();
  List<double> labelHeight() => [0, 0, 0, 0, 0.045, 0.045, 0].map((r) => height() * r).toList();
  List<double> labelWidth() => [0, 0, 0, 0, 0.2, 0.2, 0].map((r) => height() * r).toList();
  List<double> labelFontSize() => [0, 0, 0, 0, 0.025, 0.025, 0].map((r) => height() * r).toList();
  List<double> pedestrianSignalPadding() => [0.03, 0.06, 0.03, 0.015, 0.015, 0.015, 0.015].map((r) => height() * r).toList();
  List<double> trafficSignalPadding() => [0.01, 0, 0.01, 0.01, 0.04, 0.04, 0.01].map((r) => height() * r).toList();
  
  /// Countdown Number Positioning
  /// Positioning arrays for countdown display elements
  List<double> cdNumTopSpace() => [0.07, 0, 0.185, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumLeftSpace() => [0.14, 0, 0.157, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumPadding() => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumFontSize() => [0.115, 0, 0.055, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdTenLeftPadding(int countdown, bool isFlash) => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * countdown.cdTenNumber(isFlash).isOne() * r).toList();
  List<double> cdFirstLeftPadding(int countdown, bool isFlash) => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * countdown.cdFirstNumber(isFlash).isOne() * r).toList();
  
  /// Upgrade Screen Sizing
  /// Responsive sizing for premium upgrade screen elements
  double premiumTitleFontSize() => height() * 0.035;
  double premiumPriceFontSize() => height() * 0.08;
  double premiumPricePadding() => height() * 0.025;
  double upgradeButtonFontSize() => height() * 0.025;
  double upgradeTableFontSize() => height() * 0.018;
  double upgradeTableIconSize() => height() * 0.03;
  double upgradeTableHeadingHeight() => height() * 0.03;
  double upgradeTableHeight() => height() * 0.06;
  double upgradeButtonPadding() => height() * 0.006;
  double upgradeButtonMargin() => height() * 0.05;
  double upgradeMarginWidth() => height() * 0.05;
  double upgradeCircularProgressMarginBottom() => height() * 0.4;
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

  /// Settings Access Methods
  /// Convenient methods for accessing app settings with default values
  /// The string is used as the key prefix (e.g., "wait" becomes "key_wait")
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
  
  /// Button Frame Images
  /// Returns list of button frame images for each signal state (wait, red, green, off)
  /// Each index corresponds to a country's signal style (0-6)
  List<String> buttonFrame() => [
    "us/frame_us_new",                                                    // US new style
    "us/frame_us_old",                                                    // US old style
    "uk/frame_uk_new_${(this == "green") ? "g": (this == "off") ? "off": "r"}",  // UK new style
    "uk/frame_uk_old_${(this == "wait") ? "on": "off"}",                  // UK old style
    "jp/frame_jp_new",                                                    // Japan new style
    "jp/frame_jp_old",                                                    // Japan old style
    "au/frame_au_${(this == "wait") ? "on" : "off"}",                     // Australia style
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Push Button Images
  /// Returns list of push button images for on/off states
  /// Each index corresponds to a country's signal style (0-6)
  List<String> pushButtonImage() => [
    "us/button_us_new_${(this == 'on') ? 'on': 'off'}",  // US new style
    "us/button_us_old",                                  // US old style
    "uk/button_uk_new_${(this == 'on') ? 'on': 'off'}",  // UK new style
    "uk/button_uk_old",                                  // UK old style
    "jp/button_jp_new",                                  // Japan new style
    "jp/button_jp_old",                                  // Japan old style
    "au/button_au",                                      // Australia style
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Pedestrian Signal Images
  /// Returns list of pedestrian signal images for different states (flash, red, green, off)
  /// Each index corresponds to a country's signal style (0-6)
  List<String> pedestrianSignal() => [
    "us/signal_us_new2_${(this == 'green') ? 'g': (this == 'off') ? 'off': 'r'}",  // US new style
    "us/signal_us_old_${(this == 'green') ? 'g': (this == 'off') ? 'off': 'r'}",    // US old style
    "uk/signal_uk_new_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // UK new style
    "uk/signal_uk_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // UK old style
    "jp/signal_jp_new_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Japan new style
    "jp/signal_jp_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Japan old style
    "uk/signal_uk_old_${(this == 'red') ? 'r': (this == 'off') ? 'off': 'g'}",      // Australia (uses UK old)
  ].map((t) => "$pedestrianAssets$t.png").toList();

  /// Traffic Signal Images
  /// Returns list of traffic signal images for different states (yellow, red, green, off, arrow)
  /// Each index corresponds to a country's signal style (0-6)
  List<String> trafficSignal() => [
    "us/signal_us_new_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",  // US new style
    "us/signal_us_old_${(this == "yellow") ? "y": (this == "red" || this == "arrow") ? "r": "g"}",  // US old style
    "uk/signal_uk_new_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",  // UK new style
    "uk/signal_uk_old_${(this == "red" || this == "arrow") ? "r": "g"}",                            // UK old style
    "jp/signal_jp_new_${(this == "green") ? "g": (this == "red") ? "r": (this == "arrow") ? "arrow": "y"}",  // Japan new style
    "jp/signal_jp_old_${(this == "green") ? "g": (this == "red") ? "r": (this == "arrow") ? "arrow": "y"}",  // Japan old style
    "au/signal_au_${(this == "green") ? "g": (this == "yellow" || this == "off") ? "y": "r"}",      // Australia style
  ].map((t) => "$trafficAssets$t.png").toList();

  /// Settings Screen Icons
  /// Returns appropriate icons for premium settings based on state
  Icon settingsPremiumLeadingIcon(bool isReadError) =>
      (this != "") ? const Icon(Icons.shopping_cart_outlined):  // Has price - shopping cart
      (isReadError) ? const Icon(Icons.error):                   // Error state - error icon
      const Icon(Icons.downloading);                             // Loading state - download icon

  Icon? settingsPremiumTrailingIcon() =>
      (this != "") ? const Icon(Icons.arrow_forward_ios): null;  // Has price - forward arrow
}

/// Extension on int for countdown and number operations
/// Provides methods for countdown display and number formatting
extension IntExt on int {

  /// Countdown Meter Color Array
  /// Returns array of boolean values representing countdown meter segments
  /// Based on remaining time as percentage of total green time
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