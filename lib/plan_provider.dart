import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'constant.dart';
import 'extension.dart';

/// Provider for managing premium plan state across the app
final planProvider = NotifierProvider<PlanNotifier, PlanState>(PlanNotifier.new);

/// Returns the initial premium status for app startup (used from main() before ProviderScope).
/// Does not use any notifier/ref/state.
Future<bool> getInitialPremiumStatus() async {
  try {
    final localPremium = "premium".getSettingsValueBool(false);
    if (localPremium) return true;
    final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    final bool isCars = customerInfo.entitlements.active["signal_for_cars"]?.isActive ?? false;
    final bool isNoAds = customerInfo.entitlements.active["no_ads"]?.isActive ?? false;
    final bool actualPremium = isCars && isNoAds;
    if (actualPremium) {
      await Settings.setValue('key_premium', actualPremium, notify: true);
    }
    return actualPremium;
  } catch (e) {
    "Error initializing premium status: $e".debugPrint();
    return "premium".getSettingsValueBool(false);
  }
}

/// The live store price, empty while unknown. The upgrade entry is drawn only from it,
/// never from the price stored by an earlier launch, which may no longer be what is charged
class PremiumPrice {
  static final ValueNotifier<String> value = ValueNotifier("");
  /// The fetch in flight, joined by a second caller instead of starting another
  static Future<String?>? _pricing;
  /// The one prefetch per process, however often the home screen is rebuilt
  static Future<String?>? _prefetch;

  /// Fetches the price once, a few seconds after launch work, so settings open with it
  static Future<String?> prefetch() => _prefetch ??= Future.delayed(pricePrefetchDelay, load);

  /// The known price, else the fetch in flight, else a new fetch
  static Future<String?> load() async => value.value.isNotEmpty
    ? value.value
    : await (_pricing ??= _fetch().whenComplete(() => _pricing = null));

  /// The store lookup behind load(). Tests replace it so a screen's own fetch cannot race their pumps
  @visibleForTesting
  static Future<String?> Function() source = _storePrice;

  /// Forgets the price and any fetch, so each test starts from a fresh launch
  @visibleForTesting
  static void reset() {
    value.value = "";
    _pricing = null;
    _prefetch = null;
    source = _storePrice;
  }

  /// The package getOffering buys: the displayed price comes from it, so what is shown is charged
  static Package? package(Offerings offerings) => offerings.current?.lifetime;

  static Future<String?> _storePrice() async =>
    package(await Purchases.getOfferings())?.storeProduct.priceString;

  static Future<String?> _fetch() async {
    try {
      final price = await source();
      "premium price: $price".debugPrint();
      // UpgradePage reads the stored price; the settings entry point is gated on it
      if (price != null) await Settings.setValue("key_premiumPrice", price);
      value.value = price ?? "";
      return price;
    } catch (e) {
      "premium price unavailable: $e".debugPrint();
      value.value = "";
      return null;
    }
  }
}

/// Immutable state class for premium plan information
@immutable
class PlanState {
  /// Whether the user has premium access
  final bool isPremium;
  /// Whether a purchase/restore operation is currently in progress
  final bool isPurchasing;

  const PlanState({
    this.isPremium = false,
    this.isPurchasing = false,
  });
}

/// Notifier for managing premium plan state and purchase operations
class PlanNotifier extends Notifier<PlanState> {
  final PlanState? _initial;

  PlanNotifier([this._initial]);

  @override
  PlanState build() => _initial ?? const PlanState();

  /// Updates the current premium plan status
  void setCurrentPlan(bool isPremium) {
    state = PlanState(
      isPremium: isPremium,
      isPurchasing: state.isPurchasing,
    );
  }

/// Updates the purchasing state (loading indicator)
  void setPurchasing(bool isPurchasing) {
    state = PlanState(
      isPremium: state.isPremium,
      isPurchasing: isPurchasing,
    );
  }

  /// Refreshes premium status (local storage first, then RevenueCat) on a mounted notifier;
  /// for main() startup use getInitialPremiumStatus() and override planProvider instead.
  Future<void> initializePremiumStatus() async {
    final initial = await getInitialPremiumStatus();
    setCurrentPlan(initial);
  }

  /// Fetches available offerings and initiates purchase
  /// Throws exception on error for UI to handle
  Future<void> getOffering() async {
    try {
      "Getting offerings...".debugPrint();
      Offerings offerings = await Purchases.getOfferings();
      "Offerings: $offerings".debugPrint();
      // Check if there is a current offering
      if (offerings.current != null) {
        "Current offering: ${offerings.current}".debugPrint();
        "Available packages: ${offerings.current!.availablePackages}".debugPrint();
        // The lifetime package, the same one the displayed price came from
        final package = PremiumPrice.package(offerings);
        "Lifetime package: $package".debugPrint();
        // Purchase the lifetime package
        if (package != null) {
          final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
          "Purchase result: $purchaseResult".debugPrint();
          final customerInfo = purchaseResult.customerInfo;
          customerInfo.entitlements.active["no_ads"]?.isActive;
          customerInfo.entitlements.active["signal_for_cars"]?.isActive;
        } else {
          "No lifetime package available".debugPrint();
          throw Exception("No premium package available");
        }
      } else {
        "No current offering available".debugPrint();
        throw Exception("No offerings available");
      }
    } on PlatformException catch (e) {
      "PlatformException details: ${e.code}, ${e.message}, ${e.details}".debugPrint();
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Purchase Error: $errorCode");
    } catch (e) {
      "General error: $e".debugPrint();
      throw Exception("An unexpected error occurred: $e");
    }
  }

  /// Fetches current customer information from RevenueCat
  /// Updates premium status based on active entitlements
  Future<void> getCustomerInfo() async {
    try {
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      "customerInfo: $customerInfo".debugPrint();
      // Check if the user has the premium entitlement
      final bool isCars = customerInfo.entitlements.active["signal_for_cars"]?.isActive ?? false;
      final bool isNoAds = customerInfo.entitlements.active["no_ads"]?.isActive ?? false;
      "isCars: $isCars, isNoAds: $isNoAds".debugPrint();
      // Update premium status based on active entitlements
      final bool isPremium = isCars && isNoAds;
      "isPremium: $isPremium".debugPrint();
      // Update the current plan state
      setCurrentPlan(isPremium);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Purchase Error: $errorCode");
    }
  }

  /// Restores previous purchases from the app store
  /// Updates premium status based on restored entitlements
  Future<void> getRestoreInfo() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      "restoredInfo: $restoredInfo".debugPrint();
      // Check if the user has the premium entitlement
      final bool isCars = restoredInfo.entitlements.active["signal_for_cars"]?.isActive ?? false;
      final bool isNoAds = restoredInfo.entitlements.active["no_ads"]?.isActive ?? false;
      final bool isPremium = isCars && isNoAds;
      "isPremium: $isPremium, isCars: $isCars, isNoAds: $isNoAds".debugPrint();
      setCurrentPlan(isPremium);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw Exception("Restore Error: $errorCode");
    }
  }

  /// Saves premium status to local storage and updates state
  /// Called after successful purchase or restore
  Future<void> setIsPremium(bool isRestore) async {
    await Settings.setValue('key_premium', state.isPremium, notify: true);
    setPurchasing(false);
  }

  /// Main purchase/restore function called from UI
  /// Handles both new purchases and restore operations
  Future<void> buyUpgrade(bool isRestore) async {
    "isRestore: $isRestore".debugPrint();
    setPurchasing(true);
    try {
      if (!isRestore) {
        // New purchase flow
        await getOffering();
        await getCustomerInfo();
      } else {
        // Restore purchases flow
        await getRestoreInfo();
      }
      // Update local storage if premium status changed
      if (state.isPremium) {
        await setIsPremium(isRestore);
      }
      setPurchasing(false);
    } catch (e) {
      "Button tap error: $e".debugPrint();
      setPurchasing(false);

      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          return;
        }
        throw Exception("Purchase Error: $errorCode");
      }
      throw Exception("Purchase Error: An unexpected error occurred");
    }
  }
}

