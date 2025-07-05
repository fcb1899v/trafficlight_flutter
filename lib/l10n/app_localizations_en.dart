// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LETS SIGNAL';

  @override
  String get thisApp => 'This app is a realistic traffic light simulator.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get premiumPlan => 'Premium Plan';

  @override
  String get plan => 'Plan';

  @override
  String get free => 'Free';

  @override
  String get premium => 'Premium';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get toUpgrade => 'Upgrade';

  @override
  String get restore => 'Restore';

  @override
  String get toRestore => 'Restore';

  @override
  String get successPurchase => 'Purchase has been completed.';

  @override
  String get successRestore => 'Restoration has been completed.';

  @override
  String get errorPurchase => 'Purchase error';

  @override
  String get errorRestore => 'Restore error';

  @override
  String get readError => 'Read Error';

  @override
  String get failPurchase => 'Not available for purchase.';

  @override
  String get failRestore => 'The purchase history could not be found.';

  @override
  String get purchaseCancelledMessage => 'Purchase was cancelled.';

  @override
  String get paymentPendingMessage =>
      'The payment is pending. Please check the store.';

  @override
  String get purchaseInvalidMessage =>
      'This is already a pending purchase. Please check the store.';

  @override
  String get purchaseNotAllowedMessage =>
      'The purchase was not allowed. Please check your payment method.';

  @override
  String get networkErrorMessage => 'Please connect to internet.';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingError => 'Loading error';

  @override
  String get pushButton => 'Push\nButton';

  @override
  String get pedestrianSignal => 'Signal for\nPedestrians';

  @override
  String get carSignal => 'Signal for\nCars';

  @override
  String get noAds => 'No Ads';

  @override
  String get timeSettings => 'Settings of time';

  @override
  String get timeUnit => ' [sec]';

  @override
  String get waitTime => 'Waiting time of red light';

  @override
  String get goTime => 'Lighting time of green light';

  @override
  String get flashTime => 'Flashing time of green light';

  @override
  String get soundSettings => 'Settings of sound';

  @override
  String get crosswalkSound => 'Sound of crosswalk';

  @override
  String get toSettings => 'Settings';

  @override
  String get toOn => 'On';

  @override
  String get toOff => 'Off';

  @override
  String get toNew => 'New';

  @override
  String get toOld => 'Old';

  @override
  String get confirmed => 'OK';
}
