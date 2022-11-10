import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'main.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'viewmodel.dart';
import 'admob.dart';

class MySettingsPage extends HookConsumerWidget {
  const MySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();
    final BannerAd myBanner = AdmobService().getBannerAd();

    final plan = ref.read(planProvider.notifier);
    final isCarsProvider = ref.watch(planProvider).isCars;
    final isNoAdsProvider = ref.watch(planProvider).isNoAds;
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isCars = useState("cars".getSettingsValueBool(false));
    final isNoAds = useState("noAds".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));

    final waitTime = useState("wait".getSettingsValueInt(waitTime_0));
    final goTime = useState("go".getSettingsValueInt(goTime_0));
    final flashTime = useState("flash".getSettingsValueInt(flashTime_0));

    useEffect(() {
      "width: $width, height: $height".debugPrint();
      "isPremium: ${isPremium.value}, isCars: ${isCars.value}, isNoAds: ${isNoAds.value}".debugPrint();
      "isPremiumProvider: $isPremiumProvider, isCarsProvider: $isCarsProvider, isNoAdsProvider: $isNoAdsProvider".debugPrint();
      "waitTIme: ${waitTime.value}, goTime: ${goTime.value}, flashTime: ${flashTime.value}".debugPrint();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initSettings();
        await Purchases.setDebugLogsEnabled(true);
        await Purchases.configure(PurchasesConfiguration(dotenv.get("REVENUE_CAT_IOS_API_KEY")));
        await Purchases.enableAdServicesAttributionTokenCollection();
        Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
          'Received readyForPromotedProductPurchase event for productID: $productID'.debugPrint();
          try {
            final purchaseResult = await startPurchase.call();
            'Promoted purchase for productID ${purchaseResult.productIdentifier} completed, or product was'
                'already purchased. customerInfo returned is: ${purchaseResult.customerInfo}'.debugPrint();
          } on PlatformException catch (e) {
            'Error purchasing promoted product: ${e.message}'.debugPrint();
          }
        });
        if (premiumPrice.value == "") {
          final Offerings offerings = await Purchases.getOfferings();
          if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
            premiumPrice.value = offerings.current!.availablePackages[0].storeProduct.priceString;
            Settings.setValue("key_premiumPrice", premiumPrice.value);
          }
        }
        "premiumPrice: ${premiumPrice.value}".debugPrint();
      });
      return;
    }, const []);

    return WillPopScope(
      onWillPop: () async => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          title: titleText(context, context.settingsTitle()),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: signalGrayColor,
          foregroundColor: whiteColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async => Navigator.of(context).pop(),
          ),
        ),
        body: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(context.settingsSidePadding()),
                child: PreferredSize(
                  preferredSize: const Size.fromHeight(appBarHeight),
                  child: Column(children: [
                    if (!isPremiumProvider && premiumPrice.value != "") SimpleSettingsTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: context.upgradeTitle(),
                      onTap: () {},
                      child: Container(
                        padding: EdgeInsets.all(context.settingsSidePadding()),
                        child: Column(children: [
                          upgradeAppBar(context),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            alignment: Alignment.center,
                            color: Colors.white,
                            child: Column(children: [
                              premiumTitle(context),
                              upgradePrice(context, premiumPrice.value),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await Purchases.purchaseProduct(premiumProduct);
                                    final customerInfo = await Purchases.getCustomerInfo();
                                    isCars.value = customerInfo.entitlements.active["signal_for_cars"] != null;
                                    isNoAds.value = customerInfo.entitlements.active["no_ads"] != null;
                                    if (isCars.value && isNoAds.value) isPremium.value = true;
                                    "isPremium: ${isPremium.value}, isCars: ${isCars.value}, isNoAds: ${isNoAds.value}".debugPrint();
                                    await Settings.setValue<bool>('key_cars', isCars.value);
                                    await Settings.setValue<bool>('key_noAds', isNoAds.value);
                                    await Settings.setValue<bool>('key_premium', isPremium.value);
                                    plan.setCurrentPlan(isCars.value, isNoAds.value, isPremium.value);
                                    "isPremiumProvider: $isPremiumProvider, isCarsProvider: $isCarsProvider, isNoAdsProvider: $isNoAdsProvider".debugPrint();
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    "failed: $e".debugPrint();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(color: signalGrayColor, width: 2),
                                  shadowColor: transpBlackColor,
                                ),
                                child: upgradeButtonText(context),
                              ),
                              SizedBox(height: height * upgradeButtonBottomMarginRate),
                              upgradeDataTable(context),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    SliderSettingsTile(
                      defaultValue: waitTime.value.toDouble(),
                      decimalPrecision: 0,
                      min: 4, max: 30, step: 1,
                      title: context.waitTime(),
                      settingKey: 'key_wait',
                      leading: const Icon(Icons.watch_later_outlined),
                      onChange: (value) async {
                        await Settings.setValue<double>('key_wait', value, notify: true);
                        ('waitTime: ${value.toInt()}').debugPrint();
                      },
                    ),
                    SliderSettingsTile(
                      defaultValue: goTime.value.toDouble(),
                      decimalPrecision: 0,
                      min: 4, max: 30, step: 1,
                      title: context.goTime(),
                      settingKey: 'key_go',
                      leading: const Icon(Icons.watch_later_outlined),
                      onChange: (value) async {
                        await Settings.setValue<double>('key_go', value, notify: true);
                        ('goTime: ${value.toInt()}').debugPrint();
                      },
                    ),
                    SliderSettingsTile(
                      defaultValue: flashTime.value.toDouble(),
                      decimalPrecision: 0,
                      min: 4, max: 30, step: 1,
                      title: context.flashTime(),
                      settingKey: 'key_flash',
                      leading: const Icon(Icons.watch_later_outlined),
                      onChange: (value) async {
                        await Settings.setValue<double>('key_flash', value, notify: true);
                        ('flashTime: ${value.toInt()}').debugPrint();
                      },
                    ),
                    // SwitchSettingsTile(
                    //   leading: const Icon(Icons.music_note),
                    //   title: context.redSound(),
                    //   enabledLabel: context.toOn(),
                    //   disabledLabel: context.toOff(),
                    //   defaultValue: true,
                    //   settingKey: 'key_redSound',
                    //   onChange: (value) async {
                    //     await Settings.setValue<bool>('key_redSound', value, notify: true);
                    //     ('redSound: $value').debugPrint();
                    //   },
                    // ),
                    // SwitchSettingsTile(
                    //   leading: const Icon(Icons.music_note),
                    //   title: context.greenSound(),
                    //   enabledLabel: context.toOn(),
                    //   disabledLabel: context.toOff(),
                    //   defaultValue: true,
                    //   settingKey: 'key_greenSound',
                    //   onChange: (value) async {
                    //     await Settings.setValue<bool>('key_greenSound', value, notify: true);
                    //     ('greenSound: $value').debugPrint();
                    //   },
                    // ),
                  ])
                ),
              ),
            ),
          ),
          if (!isNoAds.value) adMobBannerWidget(context, myBanner, isNoAdsProvider),
        ]),
      ),
    );
  }
}







