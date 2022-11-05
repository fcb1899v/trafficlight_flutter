import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'admob.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({Key? key}) : super(key: key);
  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> {

  late int counter;
  late CustomerInfo customerInfo;
  late bool isPremium;
  late bool isTraffic;
  late bool isNoAds;
  late String price;

  @override
  void initState() {
    "call initState".debugPrint();
    super.initState();
    setState(() {
      isPremium = false;
      isTraffic = false;
      isNoAds = false;
      price = "";
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => initSettings());
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await Purchases.setDebugLogsEnabled(true);
    final PurchasesConfiguration configuration = PurchasesConfiguration(dotenv.get("REVENUE_CAT_IOS_API_KEY"));
    await Purchases.configure(configuration);
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
    if (!mounted) {
      "mounted".debugPrint();
      return;
    }
    updateCustomerStatus();
  }

  Future<void> updateCustomerStatus() async {
    final customerInfo = await Purchases.getCustomerInfo();
    final carsEntitlements = customerInfo.entitlements.active["signal_for_cars"];
    final noAdsEntitlements = customerInfo.entitlements.active["no_ads"];
    final Offerings offerings = await Purchases.getOfferings();
    setState(() {
      isTraffic = carsEntitlements != null;
      isNoAds = noAdsEntitlements != null;
      price = offerings.current!.availablePackages[0].storeProduct.priceString;
      if (isTraffic && isNoAds) isPremium = true;
    });
    "price: ${offerings.current!.availablePackages[0].storeProduct.priceString}".debugPrint();
  }

  @override
  void didChangeDependencies() {
    "call didChangeDependencies".debugPrint();
    super.didChangeDependencies();
    final locale = context.locale();
    final lang = locale.languageCode;
    final countryCode = locale.countryCode ?? "US";
    setState(() => counter = countryCode.getDefaultCounter());
    "counter: $counter, Locale: $locale, Language: $lang, CountryCode: $countryCode".debugPrint();
  }

  @override
  Widget build(BuildContext context) {
    final double width = context.width();
    final double height = context.height();
    final BannerAd myBanner = AdmobService().getBannerAd();
    "width: $width, height: $height".debugPrint();
    return WillPopScope(
      onWillPop: () async => Future.value(false),
      child: Scaffold(
        appBar: settingsAppBar(),
        body: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(context.settingsSidePadding()),
                child: settingsTiles(height),
              ),
            ),
          ),
          adMobBannerWidget(context, myBanner, isNoAds),
        ]),
      ),
    );
  }

  PreferredSize settingsAppBar() =>
      PreferredSize(
        preferredSize: const Size.fromHeight(appBarHeight),
        child: AppBar(
          title: titleText(context, counter, context.settingsTitle()),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: signalGrayColor,
          foregroundColor: whiteColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );

  Widget settingsTiles(double height) =>
      Column(children: [
        if ((Platform.isIOS || Platform.isMacOS) && !isPremium) upgradeSettingsTile(height),
        signalSwitchSettingsTile("greenSound", context.greenSound()),
        signalSwitchSettingsTile("redSound", context.redSound()),
        signalSliderSettingsTile("wait", context.waitTime()),
        signalSliderSettingsTile("go", context.goTime()),
        signalSliderSettingsTile("flash", context.flashTime()),
      ]);

  SimpleSettingsTile upgradeSettingsTile(double height) =>
      SimpleSettingsTile(
        leading: const Icon(Icons.shopping_cart_outlined),
        title: context.upgradeTitle(),
        onTap: () => context.pushSettingsPage(),
        child: Container(
          padding: EdgeInsets.all(context.settingsSidePadding()),
          child: Column(children: [
            upgradeAppBar(context, counter),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50),
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(children: [
                premiumTitle(context),
                upgradePrice(context, price),
                ElevatedButton(
                  onPressed: () async => _upgradePremium(),
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
      );

  _upgradePremium() async {
    try {
      await Purchases.purchaseProduct(premiumProduct);
      setState(() => isPremium = true);
      Purchases.addCustomerInfoUpdateListener((_) => updateCustomerStatus());
    } catch (e) {
      "failed: $e".debugPrint();
    }
    if (isPremium) {
      "isPremium: $isPremium".debugPrint();
      Navigator.of(context).pop();
    }
  }

  SwitchSettingsTile signalSwitchSettingsTile(String key, String title) =>
      SwitchSettingsTile(
        leading: const Icon(Icons.music_note),
        title: title,
        enabledLabel: context.toOn(),
        disabledLabel: context.toOff(),
        defaultValue: true,
        settingKey: 'key_$key',
        onChange: (value) async {
          await Settings.setValue<bool>('key_$key', value, notify: true);
          ('$key: $value').debugPrint();
        },
      );

  SliderSettingsTile signalSliderSettingsTile(String key, String title) =>
      SliderSettingsTile(
        defaultValue: 4,
        decimalPrecision: 0,
        min: 4,
        max: 30,
        step: 1,
        title: title,
        settingKey: 'key_$key',
        leading: const Icon(Icons.watch_later_outlined),
        onChange: (value) async {
          await Settings.setValue<double>('key_$key', value, notify: true);
          ('$key: ${value.toInt()}').debugPrint();
        },
      );
}







