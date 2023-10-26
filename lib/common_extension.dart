import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:purchases_flutter/errors.dart';
import 'my_homepage.dart';
import 'settings.dart';
import 'upgrade.dart';
import 'constant.dart';

extension ContextExt on BuildContext {

  ///Locale
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///Size
  //Common
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
  String successPurchase() => AppLocalizations.of(this)!.successPurchase;
  String successRestore() => AppLocalizations.of(this)!.successRestore;
  String successPurchaseMessage(bool isRestore) => isRestore ? successRestore(): successPurchase();
  String errorPurchase() => AppLocalizations.of(this)!.errorPurchase;
  String errorRestore() => AppLocalizations.of(this)!.errorRestore;
  String errorPurchaseTitle(bool isRestore) => isRestore ? errorRestore(): errorPurchase();
  String readError() => AppLocalizations.of(this)!.readError;
  String failPurchase() => AppLocalizations.of(this)!.failPurchase;
  String failRestore() => AppLocalizations.of(this)!.failRestore;
  String failPurchaseMessage(bool isRestore) => isRestore ? failRestore(): failPurchase();
  String purchaseCancelledMessage() => AppLocalizations.of(this)!.purchaseCancelledMessage;
  String paymentPendingMessage() => AppLocalizations.of(this)!.paymentPendingMessage;
  String purchaseInvalidMessage() => AppLocalizations.of(this)!.purchaseInvalidMessage;
  String purchaseNotAllowedMessage() => AppLocalizations.of(this)!.purchaseNotAllowedMessage;
  String networkErrorMessage() => AppLocalizations.of(this)!.networkErrorMessage;
  String purchaseErrorMessage(PurchasesErrorCode errorCode, bool isRestore) =>
    (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
    (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage():
    (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage():
    (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage():
    (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage():
    failPurchaseMessage(isRestore);
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
  String oldOrNew(bool isNew) => (isNew) ? toOld(): toNew();
  String settingsPremiumTitle(String premiumPrice, bool isReadError) =>
      (premiumPrice != "") ? premiumPlan():
      (isReadError) ? readError(): loading();

  void pushHomePage() =>
      Navigator.pushReplacement(this, MaterialPageRoute(builder: (BuildContext context) =>  const MyHomePage()));
  void pushSettingsPage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const MySettingsPage()));
  void pushUpgradePage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const MyUpgradePage()));
}

extension StringExt on String {

  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  //this is key
  int getSettingsValueInt(int defaultValue) =>
    Settings.getValue<int>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  bool getSettingsValueBool(bool defaultValue) =>
      Settings.getValue<bool>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  String getSettingsValueString(String defaultValue) =>
      Settings.getValue<String>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  //this is countryCode
  int getDefaultCounter() =>
      (this == "GB") ? 3:
      (this == "JP") ? 5:
      (this == "AU") ? 6:
      0;

  //Settings
  Icon settingsPremiumLeadingIcon(bool isReadError) =>
      (this != "") ? const Icon(Icons.shopping_cart_outlined):
      (isReadError) ? const Icon(Icons.error):
      const Icon(Icons.downloading);
  Icon? settingsPremiumTrailingIcon() =>
      (this != "") ? const Icon(Icons.arrow_forward_ios): null;



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
  double isOne() => (this == 1) ? this * 1.0: 0;
  int cdTenNumber(bool isFlash) => (this > 9 && isFlash) ? this ~/ 10: 8;
  int cdFirstNumber(bool isFlash) => (isFlash) ? this % 10: 8;
  String cdTenNumberString(bool isFlash) => "${cdTenNumber(isFlash)}";
  String cdFirstNumberString(bool isFlash) => "${cdFirstNumber(isFlash)}";
  Color cdTenColor(Color color, bool isFlash,) => (this > 9 && isFlash) ? color: signalGrayColor;
  Color cdFirstColor(Color color, bool isFlash) => (isFlash) ? color: signalGrayColor;

  //Size
  double cdTenLeftPaddingRate(int counter, bool isFlash) => cdTenNumber(isFlash).isOne() * cdNumPaddingRate[counter];
  double cdFirstLeftPaddingRate(int counter, bool isFlash) => cdFirstNumber(isFlash).isOne() * cdNumPaddingRate[counter];

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