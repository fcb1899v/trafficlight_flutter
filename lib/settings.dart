import 'dart:io';
import 'package:flutter/cupertino.dart';
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

  late double width;
  late double height;
  late int counter;
  late Locale locale;
  late String lang;
  late String countryCode;
  late BannerAd myBanner;
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
      isNoAds = false;
      price = "";
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => initSettings());
    setState(() => myBanner = AdmobService().getBannerAd());
    initPlatformState();
    Purchases.addCustomerInfoUpdateListener((_) => updateCustomerStatus());
  }

  Future<void> initPlatformState() async {
    await Purchases.setDebugLogsEnabled(true);
    final PurchasesConfiguration _configuration = PurchasesConfiguration(dotenv.get("REVENUECAT_IOS_API_KEY"));
    await Purchases.configure(_configuration);
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
    final _customerInfo = await Purchases.getCustomerInfo();
    final _carsEntitlements = _customerInfo.entitlements.active["signal_for_cars"];
    final _noAdsEntitlements = _customerInfo.entitlements.active["no_ads"];
    final Offerings offerings = await Purchases.getOfferings();
    setState(() {
      price = offerings.current!.availablePackages[0].storeProduct.priceString;
      isTraffic = _carsEntitlements != null;
      isNoAds = _noAdsEntitlements != null;
      if (isTraffic && isNoAds) isPremium = true;
    });
    "price: ${offerings.current!.availablePackages[0].storeProduct.priceString}".debugPrint();
  }

  @override
  void didChangeDependencies() {
    "call didChangeDependencies".debugPrint();
    super.didChangeDependencies();
    setState(() {
      width = context.width();
      height = context.height();
      locale = context.locale();
      lang = locale.languageCode;
      countryCode = locale.countryCode ?? "US";
      counter = countryCode.getDefaultCounter();
    });
    "width: $width, height: $height".debugPrint();
    "counter: $counter, Locale: $locale, Language: $lang, CountryCode: $countryCode".debugPrint();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => Future.value(false),
      child: Scaffold(
        appBar: settingsAppBar(),
        body: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(context.settingsSidePadding()),
                child: settingsTiles(),
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

  Widget settingsTiles() =>
      Column(children: [
        if ((Platform.isIOS || Platform.isMacOS) && !isPremium) upgradeSettingsTile(),
        signalSwitchSettingsTile("greenSound", context.greenSound()),
        signalSwitchSettingsTile("redSound", context.redSound()),
        signalSliderSettingsTile("wait", context.waitTime()),
        signalSliderSettingsTile("go", context.goTime()),
        signalSliderSettingsTile("flash", context.flashTime()),
      ]);

  SimpleSettingsTile upgradeSettingsTile() =>
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
    } catch (e) {
      "failed: $e".debugPrint();
    }
    if (isPremium) {
      "isPremium: $isPremium".debugPrint();
      Navigator.of(context).pop();
    };
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







