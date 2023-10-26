import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'plan_viewmodel.dart';
import 'main.dart';
import 'admob_banner.dart';

class MyUpgradePage extends HookConsumerWidget {
  const MyUpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();
    final apiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ? "REVENUE_CAT_IOS_API_KEY": "REVENUE_CAT_ANDROID_API_KEY");

    final plan = ref.read(planProvider.notifier);
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isPremiumRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    final isPurchasing = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initSettings();
        await Purchases.setLogLevel(LogLevel.debug);
        await Purchases.configure(PurchasesConfiguration(apiKey));
        await Purchases.enableAdServicesAttributionTokenCollection();
        Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
          'productID: $productID'.debugPrint();
          try {
            final purchaseResult = await startPurchase.call();
            'productID: ${purchaseResult.productIdentifier}'.debugPrint();
            'customerInfo: ${purchaseResult.customerInfo}'.debugPrint();
          } catch (e) {
            'Error: $e'.debugPrint();
          }
        });
      });
      "width: $width, height: $height".debugPrint();
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}, isPremiumRestore: ${isPremiumRestore.value}".debugPrint();
      return;
    }, const []);

    errorDialog(String text, bool isRestore) =>
        showCupertinoDialog(context: context, builder: (context) =>
            CupertinoAlertDialog(
              title: Text(context.errorPurchaseTitle(isRestore)),
              content: Text(text),
              actions: [
                CupertinoDialogAction(
                    child: const Text('OK', style: TextStyle(color: Colors.blue)),
                    onPressed: () {
                      isPurchasing.value = false;
                      "isPurchasing: ${isPurchasing.value}".debugPrint();
                      Navigator.pop(context);
                    }
                ),
              ],
            )
        );

    successDialog(bool isRestore) =>
        showCupertinoDialog(context: context, builder: (context) =>
            CupertinoAlertDialog(
              title: Text(context.premiumPlan()),
              content: Text(context.successPurchaseMessage(isRestore)),
              actions: [
                CupertinoDialogAction(
                    child: const Text('OK', style: TextStyle(color: Colors.blue)),
                    onPressed: () {
                      isPurchasing.value = false;
                      "isPurchasing: ${isPurchasing.value}".debugPrint();
                      context.pushHomePage();
                    }
                ),
              ],
            )
        );


    getOffering() async {
      try {
        Offerings offerings = await Purchases.getOfferings();
        if (offerings.current != null) {
          final package = offerings.current?.lifetime;
          "package: $package".debugPrint();
          final purchaserInfo = await Purchases.purchasePackage(package!);
          purchaserInfo.entitlements.active["no_ads"]?.isActive;
          purchaserInfo.entitlements.active["signal_for_cars"]?.isActive;
        }
      } on PlatformException catch (e) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        final errorMessage = context.purchaseErrorMessage(errorCode, false);
        "Purchase Error: $errorCode: $errorMessage".debugPrint();
        errorDialog(errorMessage, false);
      }
    }

    getCustomerInfo() async {
      try {
        final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        "customerInfo: $customerInfo".debugPrint();
        final bool isCars = customerInfo.entitlements.active["signal_for_cars"]!.isActive;
        final bool isNoAds = customerInfo.entitlements.active["no_ads"]!.isActive;
        "isCars: $isCars, isNoAds: $isNoAds".debugPrint();
        isPremium.value = isCars && isNoAds;
        "isPremium: ${isPremium.value}".debugPrint();
      } on PlatformException catch (e) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        final errorMessage = context.purchaseErrorMessage(errorCode, false);
        "Purchase Error: $errorCode: $errorMessage".debugPrint();
        if (context.mounted) {
          errorDialog(errorMessage, false);
        }
      }
    }

    getRestoreInfo() async {
      try {
        final restoredInfo = await Purchases.restorePurchases();
        "restoredInfo: $restoredInfo".debugPrint();
        final bool isCars = restoredInfo.entitlements.active["signal_for_cars"]!.isActive;
        final bool isNoAds = restoredInfo.entitlements.active["no_ads"]!.isActive;
        isPremium.value = isCars && isNoAds;
        "isPremium: ${isPremium.value}, isCars: $isCars, isNoAds: $isNoAds".debugPrint();
      } on PlatformException catch (e) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        final errorMessage = context.purchaseErrorMessage(errorCode, true);
        "Restore Error: $errorCode: $errorMessage".debugPrint();
        if (context.mounted) {
          errorDialog(errorMessage, true);
        }
      }
    }

    setIsPremium(bool isRestore) async {
      await Settings.setValue('key_premium', isPremium.value, notify: true);
      await plan.setCurrentPlan(isPremium.value);
      "isPremiumProvider: $isPremiumProvider".debugPrint();
      isPurchasing.value = false;
      "isPurchasing: ${isPurchasing.value}".debugPrint();
      if (context.mounted) {
        successDialog(isRestore);
      }
    }

    ///Buy Button
    GestureDetector upgradeButton(bool isRestore) => GestureDetector(
      child: upgradeButtonImage(context, isRestore),
      onTap: () async {
        "isRestore: $isRestore".debugPrint();
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        if (!isRestore) await getOffering();
        (!isRestore) ? await getCustomerInfo(): await getRestoreInfo();
        if (isPremium.value) await setIsPremium(isRestore);
      },
    );

    return Scaffold(
      appBar: settingsAppBar(context, context.premiumPlan(), isPurchasing.value),
      body: Stack(alignment: Alignment.center, children: [
          Column(children: [
            const Spacer(flex: 1),
            Container(alignment: Alignment.topCenter,
              color: transpColor,
              child: Column(children: [
                premiumTitle(context),
                upgradePrice(context, premiumPrice.value, isPremiumRestore.value),
                upgradeButton(isPremiumRestore.value),
                SizedBox(height: height * upgradeButtonBottomMarginRate),
                upgradeDataTable(context),
                SizedBox(height: height * upgradeButtonBottomMarginRate),
                upgradeButton(!isPremiumRestore.value),
              ]),
            ),
            const Spacer(flex: 1),
            if (!isPremiumProvider) const AdBannerWidget(),
          ]),
          if (isPurchasing.value) circularProgressIndicator(context),
        ]
      ),
    );
  }
}