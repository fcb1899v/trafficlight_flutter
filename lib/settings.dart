import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  late Locale locale;
  late String lang;
  late String countryCode;
  late BannerAd myBanner;

  @override
  void initState() {
    "call initState".debugPrint();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initSettings());
    setState(() => myBanner = AdmobService().getBannerAd());
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
      countryCode = locale.getCountryCode();
    });
    "width: $width, height: $height".debugPrint();
    "Locale: $locale, CountryCode: $countryCode".debugPrint();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => Future.value(false),
      child: Scaffold(
        appBar: settingsAppBar(),
        body: Container(
          height: height,
          padding: EdgeInsets.all(width.settingsSidePadding()),
          child: Column(children: [
            SingleChildScrollView(
              controller: ScrollController(),
              scrollDirection: Axis.vertical,
              child: settingsTiles(),
            ),
            const Spacer(flex: 1),
            if (height > 750) adMobBannerWidget(width, height, myBanner),
         ]),
        ),
      ),
    );
  }

  AppBar settingsAppBar() =>
      AppBar(
        title: appTitleText(lang, context.toSettings()),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: signalGrayColor,
        foregroundColor: whiteColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      );

  Widget settingsTiles() =>
      Column(children: [
        signalSwitchSettingsTile(context, "greenSound", context.greenSound()),
        signalSwitchSettingsTile(context, "redSound", context.redSound()),
        signalSliderSettingsTile("wait", context.waitTime()),
        signalSliderSettingsTile("go", context.goTime()),
        signalSliderSettingsTile("flash", context.flashTime()),
      ]);
}

SwitchSettingsTile signalSwitchSettingsTile(BuildContext context, String key, String title) =>
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
      min: 1,
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