// ===== L10nContextExt: localization helpers (part of extension.dart) =====
part of 'extension.dart';

extension L10nContextExt on BuildContext {
  /// Locale and Language Configuration
  /// Methods for accessing device locale and language-specific settings
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  /// Returns appropriate font family based on language
  /// Japanese: Noto Sans JP, Chinese: Noto Sans SC, Others: Beon
  String font(String defaultFont) =>
    (lang() == "ja") ? "notoJP":
    (lang() == "zh") ? "notoSC":
    defaultFont;

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
  String loadingError() => AppLocalizations.of(this)!.loadingError;
  String pushButton() => AppLocalizations.of(this)!.pushButton;
  String pedestrianSignal() => AppLocalizations.of(this)!.pedestrianSignal;
  String carSignal() => AppLocalizations.of(this)!.carSignal;
  String noAds() => AppLocalizations.of(this)!.noAds;
  String carSignalAvailable() => AppLocalizations.of(this)!.carSignalAvailable;
  String removeAllAds() => AppLocalizations.of(this)!.removeAllAds;
  String premiumCardPrice(String price) => AppLocalizations.of(this)!.premiumCardPrice(price);
  String toPurchase() => AppLocalizations.of(this)!.toPurchase;
  String carSignalTrialBanner() => AppLocalizations.of(this)!.carSignalTrialBanner;
  String carSignalTrialButtonLabel() => AppLocalizations.of(this)!.carSignalTrialButtonLabel;
  String carSignalTrialTag() => AppLocalizations.of(this)!.carSignalTrialTag;
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
}
