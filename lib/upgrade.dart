import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'extension.dart';
import 'constant.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';

class UpgradePage extends HookConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final planState = ref.watch(planProvider);

    final plan = ref.read(planProvider.notifier);
    final isRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    // final isPremium = useState("premium".getSettingsValueBool(false));
    // final isPurchasing = useState(false);

    final upgrade = UpgradeWidget(context,
      price: premiumPrice.value,
      isPremium: planState.isPremium,
    );

    initPurchase() {
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
      "isPremiumProvider: ${planState.isPremium}, isPremium: ${planState.isPremium}, isPremiumRestore: ${isRestore.value}".debugPrint();
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        initPurchase();
      });
      return;
    }, const []);
    useEffect(() {
      return;
    }, [planState.isPremium]);

    // getOffering() async {
    //   try {
    //     "Getting offerings...".debugPrint();
    //     Offerings offerings = await Purchases.getOfferings();
    //     "Offerings: $offerings".debugPrint();
    //     if (offerings.current != null) {
    //       "Current offering: ${offerings.current}".debugPrint();
    //       "Available packages: ${offerings.current!.availablePackages}".debugPrint();
    //       final package = offerings.current?.lifetime;
    //       "Lifetime package: $package".debugPrint();
    //       if (package != null) {
    //         final purchaserInfo = await Purchases.purchasePackage(package);
    //         "Purchase result: $purchaserInfo".debugPrint();
    //         purchaserInfo.entitlements.active["no_ads"]?.isActive;
    //         purchaserInfo.entitlements.active["signal_for_cars"]?.isActive;
    //       } else {
    //         "No lifetime package available".debugPrint();
    //         upgrade.purchaseDialog(
    //           message: "No premium package available",
    //           isSuccess: false,
    //           isRestore: false,
    //         );
    //         isPurchasing.value = false;
    //         "isPurchasing: ${isPurchasing.value}".debugPrint();
    //       }
    //     } else {
    //       "No current offering available".debugPrint();
    //       upgrade.purchaseDialog(
    //         message: "No offerings available",
    //         isSuccess: false,
    //         isRestore: false,
    //       );
    //       isPurchasing.value = false;
    //       "isPurchasing: ${isPurchasing.value}".debugPrint();
    //     }
    //   } on PlatformException catch (e) {
    //     "PlatformException details: ${e.code}, ${e.message}, ${e.details}".debugPrint();
    //     final errorCode = PurchasesErrorHelper.getErrorCode(e);
    //     final errorMessage = (context.mounted) ? context.purchaseErrorMessage(errorCode, false): "";
    //     "Purchase Error: $errorCode: $errorMessage".debugPrint();
    //     upgrade.purchaseDialog(
    //       message: errorMessage,
    //       isSuccess: false,
    //       isRestore: false,
    //     );
    //     isPurchasing.value = false;
    //     "isPurchasing: ${isPurchasing.value}".debugPrint();
    //   } catch (e) {
    //     "General error: $e".debugPrint();
    //     upgrade.purchaseDialog(
    //       message: "An unexpected error occurred: $e",
    //       isSuccess: false,
    //       isRestore: false,
    //     );
    //     isPurchasing.value = false;
    //     "isPurchasing: ${isPurchasing.value}".debugPrint();
    //   }
    // }

    // getCustomerInfo() async {
    //   try {
    //     final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    //     "customerInfo: $customerInfo".debugPrint();
    //     final bool isCars = customerInfo.entitlements.active["signal_for_cars"]!.isActive;
    //     final bool isNoAds = customerInfo.entitlements.active["no_ads"]!.isActive;
    //     "isCars: $isCars, isNoAds: $isNoAds".debugPrint();
    //     isPremium.value = isCars && isNoAds;
    //     "isPremium: ${isPremium.value}".debugPrint();
    //   } on PlatformException catch (e) {
    //     final errorCode = PurchasesErrorHelper.getErrorCode(e);
    //     final errorMessage = (context.mounted) ? context.purchaseErrorMessage(errorCode, false): "";
    //     "Purchase Error: $errorCode: $errorMessage".debugPrint();
    //     upgrade.purchaseDialog(
    //       message: errorMessage,
    //       isSuccess: false,
    //       isRestore: false,
    //     );
    //     isPurchasing.value = false;
    //     "isPurchasing: ${isPurchasing.value}".debugPrint();
    //   }
    // }

    // getRestoreInfo() async {
    //   try {
    //     final restoredInfo = await Purchases.restorePurchases();
    //     "restoredInfo: $restoredInfo".debugPrint();
    //     final bool isCars = restoredInfo.entitlements.active["signal_for_cars"]!.isActive;
    //     final bool isNoAds = restoredInfo.entitlements.active["no_ads"]!.isActive;
    //     isPremium.value = isCars && isNoAds;
    //     "isPremium: ${isPremium.value}, isCars: $isCars, isNoAds: $isNoAds".debugPrint();
    //   } on PlatformException catch (e) {
    //     final errorCode = PurchasesErrorHelper.getErrorCode(e);
    //     final errorMessage = (context.mounted) ? context.purchaseErrorMessage(errorCode, true): "";
    //     "Restore Error: $errorCode: $errorMessage".debugPrint();
    //     upgrade.purchaseDialog(
    //       message: errorMessage,
    //       isSuccess: false,
    //       isRestore: false,
    //     );
    //     isPurchasing.value = false;
    //     "isPurchasing: ${isPurchasing.value}".debugPrint();
    //   }
    // }

    // setIsPremium(bool isRestore) async {
    //   await Settings.setValue('key_premium', isPremium.value, notify: true);
    //   plan.setCurrentPlan(isPremium.value);
    //   "isPremiumProvider: $isPremiumProvider".debugPrint();
    //   isPurchasing.value = false;
    //   "isPurchasing: ${isPurchasing.value}".debugPrint();
    //   upgrade.purchaseDialog(
    //     message: "",
    //     isSuccess: true,
    //     isRestore: isRestore
    //   );
    //   isPurchasing.value = false;
    //   "isPurchasing: ${isPurchasing.value}".debugPrint();
    // }

    ///Buy Button
    buyUpgrade(bool isRestore) async {
      "isRestore: $isRestore".debugPrint();
      // isPurchasing.value = true;
      // "isPurchasing: ${isPurchasing.value}".debugPrint();
      try {
        await plan.buyUpgrade(isRestore);
        upgrade.purchaseDialog(
          message: "",
          isSuccess: true,
          isRestore: isRestore
        );
        // if (!isRestore) {
        //   await getOffering();
        //   await getCustomerInfo();
        // } else {
        //   await getRestoreInfo();
        // }
        // if (isPremium.value) {
        //   await setIsPremium(isRestore);
        // }
        // isPurchasing.value = false;
      } catch (e) {
        "Button tap error: $e".debugPrint();
        upgrade.purchaseDialog(
          message: e.toString(),
          isSuccess: false,
          isRestore: isRestore,
        );
        // upgrade.purchaseDialog(
        //   message: "An error occurred: $e",
        //   isSuccess: false,
        //   isRestore: isRestore,
        // );
        // isPurchasing.value = false;
        // "isPurchasing: ${isPurchasing.value}".debugPrint();
      }
    }

    return Scaffold(
      appBar: upgrade.upgradeAppBar(),
      body: Stack(alignment: Alignment.center, children: [
        Column(children: [
          const Spacer(flex: 1),
          Container(alignment: Alignment.topCenter,
            color: transpColor,
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              upgrade.upgradePrice(),
              upgrade.upgradeButton(isRestore.value,
                onTap: () => buyUpgrade(isRestore.value)
              ),
              upgrade.upgradeDataTable(),
              upgrade.upgradeButton(!isRestore.value,
                onTap: () => buyUpgrade(!isRestore.value)
              ),
            ]),
          ),
          const Spacer(flex: 2),
          if (!planState.isPremium) const AdBannerWidget(),
        ]),
        if (planState.isPurchasing) upgrade.circularProgressIndicator(),
      ]
      ),
    );
  }
}

class UpgradeWidget {

  final BuildContext context;
  final String price;
  final bool isPremium;

  UpgradeWidget(this.context, {
    required this.price,
    required this.isPremium,
  });

  PreferredSize upgradeAppBar() => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.premiumPlan(),
        style: TextStyle(
          fontFamily: context.titleFont(),
          fontSize: context.appBarFontSize(),
          fontWeight: FontWeight.bold,
          color: whiteColor,
          decoration: TextDecoration.none
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: signalGrayColor,
      foregroundColor: whiteColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () async {
          if (context.mounted) context.pushHomePage();
        },
      ),
    ),
  );

  ///Upgrade
  Text premiumTitle() => Text(context.premiumPlan(),
    style: TextStyle(
      fontSize: context.premiumTitleFontSize(),
      fontWeight: FontWeight.bold,
      fontFamily: context.titleFont(),
      color: signalGrayColor,
      decoration: TextDecoration.none
    )
  );

  Widget upgradePrice() => Container(
    padding: EdgeInsets.all(context.premiumPricePadding()),
    child: (!isPremium) ? Text(price,
      style: TextStyle(
        fontSize: context.premiumPriceFontSize(),
        fontWeight: FontWeight.bold,
        fontFamily: context.titleFont(),
        color: yellowColor,
        decoration: TextDecoration.none
      )
    ): null,
  );

  Widget upgradeButton(bool isRestore, {
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Material(
      elevation: upgradeButtonElevation,
      child: Container(
        padding: EdgeInsets.all(context.upgradeButtonPadding()),
        decoration: BoxDecoration(
          color: isRestore ? greenColor: yellowColor,
          border: Border.all(color: signalGrayColor, width: upgradeButtonBorderWidth),
          borderRadius: BorderRadius.circular(upgradeButtonBorderRadius),
        ),
        child: Text(isRestore ? context.toRestore(): context.toUpgrade(),
          style: TextStyle(
            fontSize: context.upgradeButtonFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: context.titleFont(),
            color: isRestore ? whiteColor: signalGrayColor,
            decoration: TextDecoration.none
          )
        )
      )
    )
  );

  Widget upgradeDataTable() => Container(
    margin: EdgeInsets.symmetric(vertical: context.upgradeButtonMargin()),
    child: DataTable(
      headingRowHeight: context.upgradeTableHeadingHeight(),
      headingRowColor: WidgetStateColor.resolveWith((states) => signalGrayColor),
      headingTextStyle: const TextStyle(color: whiteColor),
      dividerThickness: upgradeTableDividerWidth,
      dataRowMaxHeight: context.upgradeTableHeight(),
      dataRowMinHeight: context.upgradeTableHeight(),
      columns: [
        dataColumnLabel(context.plan()),
        dataColumnLabel(context.free()),
        dataColumnLabel(context.premium()),
      ],
      rows: [
        tableDataRow(context.pushButton(), whiteColor, false),
        tableDataRow(context.pedestrianSignal(), transpGrayColor, false),
        tableDataRow(context.carSignal(), whiteColor, true),
        tableDataRow(context.noAds(), transpGrayColor, true),
      ],
    )
  );

  DataColumn dataColumnLabel(String text) => DataColumn(
    label: Expanded(
      child: Text(text,
        style: upgradeTextStyle(context.upgradeTableFontSize(), whiteColor),
        textAlign: TextAlign.center,
      ),
    ),
  );

  DataRow tableDataRow(String title, Color color, bool isPremium) => DataRow(
    color: WidgetStateColor.resolveWith((states) => color),
    cells: [
      DataCell(Text(title,
        style: upgradeTextStyle(context.upgradeTableFontSize(), signalGrayColor),
        textAlign: TextAlign.left,
      )),
      isPremium ?
      iconDataCell(Icons.not_interested, redColor):
      iconDataCell(Icons.check_circle, greenColor),
      iconDataCell(Icons.check_circle, greenColor),
    ]
  );

  TextStyle upgradeTextStyle(double fontSize, Color color) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    fontFamily: context.titleFont(),
    color: color,
    decoration: TextDecoration.none
  );

  DataCell iconDataCell(IconData icon, Color color) => DataCell(
    Center(child:
      Icon(icon,
        color: color,
        size: context.upgradeTableIconSize()
      )
    ),
  );

  Widget circularProgressIndicator() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: greenColor),
      SizedBox(height: context.upgradeCircularProgressMarginBottom()),
    ]
  );

  Future<void> purchaseDialog({
    required String message,
    required bool isSuccess,
    required bool isRestore,
  }) => showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(isSuccess ? context.premiumPlan(): context.errorPurchaseTitle(isRestore)),
      content: Text(isSuccess ? context.successPurchaseMessage(isRestore): message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => isSuccess ? context.pushHomePage():Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: Colors.blue))
        ),
      ],
    )
  );
}
