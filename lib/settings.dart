import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:settings_ui/settings_ui.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'viewmodel.dart';
import 'main.dart';
import 'admob_banner.dart';

class MySettingsPage extends HookConsumerWidget {
  const MySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();
    final apiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ? "REVENUE_CAT_IOS_API_KEY": "REVENUE_CAT_ANDROID_API_KEY");

    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isPremiumRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    final isReadError = useState(false);
    final waitTime = useState("wait".getSettingsValueInt(waitTime_0));
    final goTime = useState("go".getSettingsValueInt(goTime_0));
    final flashTime = useState("flash".getSettingsValueInt(flashTime_0));
    final isSound = useState('sound'.getSettingsValueBool(true));

    getPremiumPrice() async {
      final Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        premiumPrice.value = offerings.current!.availablePackages[0].storeProduct.priceString;
        await Settings.setValue("key_premiumPrice", premiumPrice.value);
      }
    }

    setTime(int time, String key) async {
      await Settings.setValue('key_$key', time, notify: true);
      ('${key}Time: $time').debugPrint();
      if (key == "wait") waitTime.value = time;
      if (key == "go") goTime.value = time;
      if (key == "flash") flashTime.value = time;
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initSettings();
        if (!isPremiumProvider) {
          await Purchases.setLogLevel(LogLevel.debug);
          await Purchases.configure(PurchasesConfiguration(apiKey));
          await Purchases.enableAdServicesAttributionTokenCollection();
          Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
            'productID: $productID'.debugPrint();
            try {
              final purchaseResult = await startPurchase.call();
              'productID: ${purchaseResult.productIdentifier}'.debugPrint();
              'customerInfo: ${purchaseResult.customerInfo}'.debugPrint();
            } on PlatformException catch (e) {
              'Error: ${e.message}'.debugPrint();
            }
          });
          if (premiumPrice.value == "") {
            try {
              getPremiumPrice();
            } on PlatformException catch (e) {
              isReadError.value = true;
              'ReadError: ${isReadError.value}, Error: ${e.message}'.debugPrint();
            }
          }
        }
      });
      "width: $width, height: $height".debugPrint();
      "waitTIme: ${waitTime.value}, goTime: ${goTime.value}, flashTime: ${flashTime.value}".debugPrint();
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}, isPremiumRestore: ${isPremiumRestore.value}".debugPrint();
      return;
    }, const []);

    return Scaffold(
      appBar: settingsAppBar(context, context.settingsTitle(), false),
      body: SettingsList(sections: [
        ///Waiting Time
        SettingsSection(title: Text(context.timeSettings()),
          tiles: [
            CustomSettingsTile(
              child: Container(
                padding: settingsTitlePadding(false),
                decoration: settingsTileDecoration(true, false),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingsTitle(context, context.waitTime(), waitTime.value),
                    SliderTheme(
                      data: sliderTheme(context, transpRedColor),
                      child: Slider(
                        value: waitTime.value.toDouble(),
                        max: maxTime.toDouble(),
                        min: minTime.toDouble(),
                        divisions: maxTime - minTime + 1,
                        onChanged: (double value) => setTime(value.toInt(), 'wait')
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ///Going Time
            CustomSettingsTile(
              child: Container(
                padding: settingsTitlePadding(false),
                color: (Platform.isIOS || Platform.isMacOS) ? whiteColor: transpColor,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingsTitle(context, context.goTime(), goTime.value),
                    SliderTheme(
                      data: sliderTheme(context, transpGreenColor),
                      child: Slider(
                        value: goTime.value.toDouble(),
                        max: maxTime.toDouble(),
                        min: minTime.toDouble(),
                        divisions: maxTime - minTime + 1,
                        onChanged: (double value) => setTime(value.toInt(), 'go')
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ///Flashing Time
            CustomSettingsTile(
              child: Container(
                padding: settingsTitlePadding(true),
                decoration: settingsTileDecoration(false, true),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingsTitle(context, context.flashTime(), flashTime.value),
                    SliderTheme(
                      data: sliderTheme(context, transpYellowColor),
                      child: Slider(
                        value: flashTime.value.toDouble(),
                        max: maxTime.toDouble(),
                        min: minTime.toDouble(),
                        divisions: maxTime - minTime + 1,
                        onChanged: (double value) => setTime(value.toInt(), 'flash')
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ),
        ///Sound On/Off
        SettingsSection(
          title: Text(context.soundSettings()),
          tiles: [
            SettingsTile.switchTile(
              leading: const Icon(Icons.music_note),
              activeSwitchColor: transpGreenColor,
              title: Text(context.crosswalkSound()),
              initialValue: isSound.value,
              onToggle: (value) async {
                await Settings.setValue<bool>('key_sound', value, notify: true);
                ('sound: $value').debugPrint();
                isSound.value = value;
              },
            )
          ]
        ),
        ///Premium Plan
        if (!isPremiumProvider) SettingsSection(
          title: Text(context.upgrade()),
          tiles: [
            SettingsTile(
              title: Text(context.settingsPremiumTitle(premiumPrice.value, isReadError.value)),
              leading: premiumPrice.value.settingsPremiumLeadingIcon(isReadError.value),
              trailing: premiumPrice.value.settingsPremiumTrailingIcon(),
              onPressed: (context) => (premiumPrice.value != "") ? context.pushUpgradePage(): null,
            ),
          ]
        ),
        ///AdMob Banner
        SettingsSection(
          tiles: [
            CustomSettingsTile(
              child: (isPremiumProvider) ?
                SizedBox(height: context.admobHeight()):
                const AdBannerWidget(),
            ),
          ]
        ),
      ])
    );
  }
}