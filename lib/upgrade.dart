import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'extension.dart';
import 'constant.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';

/// Upgrade page widget that handles premium plan purchases and restorations
/// Uses Riverpod for state management and Flutter Hooks for local state
class UpgradePage extends HookConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the plan state from the provider
    final planState = ref.watch(planProvider);
    // Read the plan notifier for actions
    final plan = ref.read(planProvider.notifier);
    // Local state for restore mode and premium price
    final isRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    // Create upgrade widget instance
    final upgrade = UpgradeWidget(context,
      price: premiumPrice.value,
      isPremium: planState.isPremium,
    );
    /// Initialize purchase functionality and set up promoted product listener
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
    // Initialize settings and purchase functionality on first frame
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        initPurchase();
      });
      return;
    }, const []);
    // Effect to handle premium state changes
    useEffect(() {
      return;
    }, [planState.isPremium]);
    /// Handle purchase or restore action
    /// @param isRestore Whether this is a restore operation or new purchase
    buyUpgrade(bool isRestore) async {
      "isRestore: $isRestore".debugPrint();
      try {
        await plan.buyUpgrade(isRestore);
        upgrade.purchaseDialog(
          isSuccess: true,
          isRestore: isRestore,
        );
      } on PlatformException catch (e) {
        "Button tap error: $e".debugPrint();
        upgrade.purchaseDialog(
          isSuccess: false,
          isRestore: isRestore,
          errorCode: PurchasesErrorHelper.getErrorCode(e),
        );
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
          // Show ad banner only for non-premium users
          if (!planState.isPremium) const AdBannerWidget(),
        ]),
        // Show loading indicator during purchase process
        if (planState.isPurchasing) upgrade.circularProgressIndicator(),
      ]
      ),
    );
  }
}

/// Widget class that handles all upgrade-related UI components
/// Manages the visual presentation of upgrade options, pricing, and purchase flow
class UpgradeWidget {

  final BuildContext context;
  final String price;
  final bool isPremium;

  UpgradeWidget(this.context, {
    required this.price,
    required this.isPremium,
  });

  /// Create the app bar for the upgrade page
  PreferredSize upgradeAppBar() => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.premiumPlan(),
        style: TextStyle(
          fontFamily: context.font(),
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

  /// Create the premium plan title text
  Text premiumTitle() => Text(context.premiumPlan(),
    style: TextStyle(
      fontSize: context.premiumTitleFontSize(),
      fontWeight: FontWeight.bold,
      fontFamily: context.font(),
      color: signalGrayColor,
      decoration: TextDecoration.none
    )
  );

  /// Display the premium price (only shown for non-premium users)
  Widget upgradePrice() => Container(
    padding: EdgeInsets.all(context.premiumPricePadding()),
    child: (!isPremium) ? Text(price,
      style: TextStyle(
        fontSize: context.premiumPriceFontSize(),
        fontWeight: FontWeight.bold,
        fontFamily: context.font(),
        color: yellowColor,
        decoration: TextDecoration.none
      )
    ): null,
  );

  /// Create upgrade or restore button with different styling based on action type
  /// @param isRestore Whether this button triggers restore or purchase
  /// @param onTap Callback function when button is tapped
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
            fontFamily: context.font(),
            color: isRestore ? whiteColor: signalGrayColor,
            decoration: TextDecoration.none
          )
        )
      )
    )
  );

  /// Create comparison table showing free vs premium features
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

  /// Create column header for the comparison table
  DataColumn dataColumnLabel(String text) => DataColumn(
    label: Expanded(
      child: Text(text,
        style: upgradeTextStyle(context.upgradeTableFontSize(), whiteColor),
        textAlign: TextAlign.center,
      ),
    ),
  );

  /// Create table row showing feature availability
  /// @param title Feature name
  /// @param color Row background color
  /// @param isPremium Whether this feature is premium-only
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

  /// Create consistent text style for upgrade UI elements
  TextStyle upgradeTextStyle(double fontSize, Color color) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    fontFamily: context.font(),
    color: color,
    decoration: TextDecoration.none
  );

  /// Create data cell with centered icon
  DataCell iconDataCell(IconData icon, Color color) => DataCell(
    Center(child:
      Icon(icon,
        color: color,
        size: context.upgradeTableIconSize()
      )
    ),
  );

  /// Show loading indicator during purchase process
  Widget circularProgressIndicator() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: greenColor),
      SizedBox(height: context.upgradeCircularProgressMarginBottom()),
    ]
  );

  /// Display purchase result dialog (success or error)
  /// @param isSuccess Whether the purchase/restore was successful
  /// @param isRestore Whether this was a restore operation
  /// @param errorCode Error code if the operation failed
  Future<void> purchaseDialog({
    required bool isSuccess,
    required bool isRestore,
    PurchasesErrorCode? errorCode,
  }) => showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(isSuccess ? context.premiumPlan(): context.errorPurchaseTitle(isRestore)),
      content: Text(isSuccess ? context.successPurchaseMessage(isRestore): context.purchaseErrorMessage(errorCode, isRestore)),
      actions: [
        CupertinoDialogAction(
          onPressed: () => isSuccess ? context.pushHomePage():Navigator.pop(context),
          child: Text(context.confirmed(), style: TextStyle(color: Colors.blue))
        ),
      ],
    )
  );
}
