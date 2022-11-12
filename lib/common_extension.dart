import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'settings.dart';
import 'constant.dart';

extension ContextExt on BuildContext {

  ///Locale
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///Size
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  //Settings
  double settingsSidePadding() => width() < 600 ? 10: width() / 2 - 290;
  //Admob
  double admobHeight() => (height() < 750) ? 50: (height() < 1000) ? 50 + (height() - 750) / 5: 100;
  double admobWidth() => width() - 100;

  ///Localization
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String settingsTitle() => AppLocalizations.of(this)!.settingsTitle;
  String upgradeTitle() => AppLocalizations.of(this)!.upgradeTitle;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String plan() => AppLocalizations.of(this)!.plan;
  String free() => AppLocalizations.of(this)!.free;
  String premium() => AppLocalizations.of(this)!.premium;
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String restore() => AppLocalizations.of(this)!.restore;
  String restoreCompleted() => AppLocalizations.of(this)!.restoreCompleted;
  String pushButton() => AppLocalizations.of(this)!.pushButton;
  String pedestrianSignal() => AppLocalizations.of(this)!.pedestrianSignal;
  String carSignal() => AppLocalizations.of(this)!.carSignal;
  String noAds() => AppLocalizations.of(this)!.noAds;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String waitTime() => AppLocalizations.of(this)!.waitTime;
  String goTime() => AppLocalizations.of(this)!.goTime;
  String flashTime() => AppLocalizations.of(this)!.flashTime;
  String crosswalkSound() => AppLocalizations.of(this)!.crosswalkSound;
  String toSettings() => AppLocalizations.of(this)!.toSettings;
  String toOn() => AppLocalizations.of(this)!.toOn;
  String toOff() => AppLocalizations.of(this)!.toOff;
  String toNew() => AppLocalizations.of(this)!.toNew;
  String toOld() => AppLocalizations.of(this)!.toOld;
  String confirmed() => AppLocalizations.of(this)!.confirmed;
  String oldOrNew(bool isNew) => (isNew) ? toOld(): toNew();

  void pushSettingsPage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const MySettingsPage()));
}

extension StringExt on String {

  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  //this is key
  int getSettingsValueInt(int defaultValue) =>
      Settings.getValue<double>("key_$this", defaultValue: defaultValue.toDouble())?.toInt() ?? defaultValue;

  bool getSettingsValueBool(bool defaultValue) =>
      Settings.getValue<bool>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  String getSettingsValueString(String defaultValue) =>
      Settings.getValue<String>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  //this is countryCode
  int getDefaultCounter() =>
      (this == "GB") ? 2:
      (this == "JP") ? 4:
      (this == "AU") ? 6:
      0;
}


extension IntExt on int {

  //this is countDown
  List<bool> countMeterColor(int greenTime) =>
      (this / greenTime > 0.875) ? [true, true, true, true, true, true, true, true]:
      (this / greenTime > 0.750) ? [false, true, true, true, true, true, true, true]:
      (this / greenTime > 0.625) ? [false, false, true, true, true, true, true, true]:
      (this / greenTime > 0.500) ? [false, false, false, true, true, true, true, true]:
      (this / greenTime > 0.375) ? [false, false, false, false, true, true, true, true]:
      (this / greenTime > 0.250) ? [false, false, false, false, false, true, true, true]:
      (this / greenTime > 0.125) ? [false, false, false, false, false, false, true, true]:
      (this / greenTime > 0) ? [false, false, false, false, false, false, false, true]:
      [false, false, false, false, false, false, false, false];

  int cdNumber(bool isFlash, bool is10) =>
      (is10 && this > 9 && isFlash) ? this ~/ 10:
      (!is10 && isFlash) ? this % 10:
      8;

  double isOne() => (this == 1) ? this * 1.0: 0;

  Color cdNumColor(Color color, bool isFlash, bool is10) =>
      (((is10 && this > 9) || !is10) && isFlash) ? color: signalGrayColor;

  //this is counter
  String trafficSignalImageString(bool isGreen, isYellow, isArrow, opaque) =>
      (isYellow) ? trafficSignalYellowString[this]:
      (isArrow) ? trafficSignalArrowString[this]:
      (!isGreen) ? trafficSignalGreenString[this]:
      trafficSignalRedString[this];

  String pedestrianSignalImageString(bool isGreen, isFlash, opaque) =>
      (isGreen && isFlash && opaque) ? pedestrianSignalOffString[this]:
      (isGreen && isFlash) ? pedestrianSignalFlashString[this]:
      (isGreen) ? pedestrianSignalGreenString[this]:
      pedestrianSignalRedString[this];

  String buttonFrameImageString(bool isGreen, isFlash, opaque, isPressed) =>
      (!isGreen && isPressed) ? buttonFrameWaitString[this]:
      (!isGreen) ? buttonFrameRedString[this]:
      (isFlash && opaque) ? buttonFrameOffString[this]:
      buttonFrameGreenString[this];

  String pushButtonImageString(bool isGreen, isPressed) =>
      (!isGreen && isPressed) ? pushButtonOnString[this]:
      pushButtonOffString[this];

  String jpFrameMessage(bool isPressed, isGreen, bool isUpper) =>
      (!isGreen && isPressed && isUpper) ? "おまちください":
      (!isGreen && !isPressed && this == 5 && !isUpper) ? "おしてください":
      (!isGreen && !isPressed && this == 4 && !isUpper) ? "ふれてください":
      "";
}