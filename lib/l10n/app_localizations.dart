import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh')
  ];

  ///
  ///
  /// In en, this message translates to:
  /// **'LETS SIGNAL'**
  String get appTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'This app is a realistic traffic light simulator.'**
  String get thisApp;

  ///
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlan;

  ///
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  ///
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  ///
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  ///
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  ///
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get toUpgrade;

  ///
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get toRestore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Purchase has been completed.'**
  String get successPurchase;

  ///
  ///
  /// In en, this message translates to:
  /// **'Restoration has been completed.'**
  String get successRestore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Purchase error'**
  String get errorPurchase;

  /// No description provided for @errorRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore error'**
  String get errorRestore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Read Error'**
  String get readError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Not available for purchase.'**
  String get failPurchase;

  ///
  ///
  /// In en, this message translates to:
  /// **'The purchase history could not be found.'**
  String get failRestore;

  ///
  ///
  /// In en, this message translates to:
  /// **'Purchase was cancelled.'**
  String get purchaseCancelledMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'The payment is pending. Please check the store.'**
  String get paymentPendingMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'This is already a pending purchase. Please check the store.'**
  String get purchaseInvalidMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'The purchase was not allowed. Please check your payment method.'**
  String get purchaseNotAllowedMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please connect to internet.'**
  String get networkErrorMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  ///
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  ///
  ///
  /// In en, this message translates to:
  /// **'Push\nButton'**
  String get pushButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Signal for\nPedestrians'**
  String get pedestrianSignal;

  ///
  ///
  /// In en, this message translates to:
  /// **'Signal for\nCars'**
  String get carSignal;

  ///
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get noAds;

  ///
  ///
  /// In en, this message translates to:
  /// **'Settings of time'**
  String get timeSettings;

  ///
  ///
  /// In en, this message translates to:
  /// **' [sec]'**
  String get timeUnit;

  ///
  ///
  /// In en, this message translates to:
  /// **'Waiting time of red light'**
  String get waitTime;

  ///
  ///
  /// In en, this message translates to:
  /// **'Lighting time of green light'**
  String get goTime;

  ///
  ///
  /// In en, this message translates to:
  /// **'Flashing time of green light'**
  String get flashTime;

  ///
  ///
  /// In en, this message translates to:
  /// **'Settings of sound'**
  String get soundSettings;

  ///
  ///
  /// In en, this message translates to:
  /// **'Sound of crosswalk'**
  String get crosswalkSound;

  /// No description provided for @toSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get toSettings;

  /// No description provided for @toOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get toOn;

  /// No description provided for @toOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get toOff;

  /// No description provided for @toNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get toNew;

  /// No description provided for @toOld.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get toOld;

  ///
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
