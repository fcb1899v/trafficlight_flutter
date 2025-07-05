import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'extension.dart';

/// Provider for managing premium plan state across the app
final planProvider = StateNotifierProvider<PlanNotifier, PlanState>(
  (ref) => PlanNotifier()
);

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

/// StateNotifier for managing premium plan state and purchase operations
class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier(): super(const PlanState());

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

  /// Initializes premium status on app startup
  /// Checks local storage first, then validates with RevenueCat if needed
  Future<void> initializePremiumStatus() async {
    try {
      // Load premium status from local storage first
      final localPremium = "premium".getSettingsValueBool(false);
      setCurrentPlan(localPremium);
      // Only check RevenueCat if local storage shows non-premium
      // This avoids unnecessary API calls for confirmed premium users
      if (!localPremium) {
        // Try automatic restore
        final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        final bool isCars = customerInfo.entitlements.active["signal_for_cars"]?.isActive ?? false;
        final bool isNoAds = customerInfo.entitlements.active["no_ads"]?.isActive ?? false;
        final bool actualPremium = isCars && isNoAds;        
        // Update local storage and state if user actually has premium
        if (actualPremium) {
          await Settings.setValue('key_premium', actualPremium, notify: true);
          setCurrentPlan(actualPremium);
        }
      }
    } catch (e) {
      "Error initializing premium status: $e".debugPrint();
      // Fallback to local storage value on error
      final localPremium = "premium".getSettingsValueBool(false);
      setCurrentPlan(localPremium);
    }
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
        // Get the lifetime package
        final package = offerings.current?.lifetime;
        "Lifetime package: $package".debugPrint();
        // Purchase the lifetime package
        if (package != null) {
          final purchaserInfo = await Purchases.purchasePackage(package);
          "Purchase result: $purchaserInfo".debugPrint();
          purchaserInfo.entitlements.active["no_ads"]?.isActive;
          purchaserInfo.entitlements.active["signal_for_cars"]?.isActive;
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
    }
  }


}

