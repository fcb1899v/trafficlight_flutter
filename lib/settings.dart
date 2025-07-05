import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:settings_ui/settings_ui.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';

/// Settings page widget that manages app configuration and premium plan access
/// Uses Riverpod for state management and Flutter Hooks for local state
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch time-related state providers
    final waitTime = ref.watch(waitTimeProvider);
    final goTime = ref.watch(goTimeProvider);
    final flashTime = ref.watch(flashTimeProvider);
    final isSound = ref.watch(isSoundProvider);
    // Watch premium status and local state
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isPremiumRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    final isReadError = useState(false);
    // Create settings widget instance
    final settings = SettingsWidget(context,
      waitTime: waitTime,
      goTime: goTime,
      flashTime: flashTime,
      isSound: isSound,
    );
    /// Fetch premium price from RevenueCat offerings
    getPremiumPrice() async {
      final Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        premiumPrice.value = offerings.current!.availablePackages[0].storeProduct.priceString;
        await Settings.setValue("key_premiumPrice", premiumPrice.value);
      }
    }
    /// Update time settings and sync with provider state
    /// @param time New time value
    /// @param key Setting key (wait, go, flash)
    Future<void> setTime(int time, String key) async {
      await Settings.setValue('key_$key', time, notify: true);
      ('${key}Time: $time').debugPrint();
      if (key == "wait") ref.read(waitTimeProvider.notifier).state = time;
      if (key == "go") ref.read(goTimeProvider.notifier).state = time;
      if (key == "flash") ref.read(flashTimeProvider.notifier).state = time;
    }
    /// Update sound setting and sync with provider state
    /// @param value New sound setting value
    Future<void> setSound(bool value) async {
      await Settings.setValue<bool>('key_sound', value, notify: true);
      'sound: $value'.debugPrint();
      ref.read(isSoundProvider.notifier).state = value;
    }
    // Initialize settings and premium functionality on first frame
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        if (!isPremiumProvider) {
          // Set up promoted product purchase listener for non-premium users
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
          // Fetch premium price if not already cached
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
      "waitTime: $waitTime, goTime: $goTime, flashTime: $flashTime, isSound: $isSound".debugPrint();
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}, isPremiumRestore: ${isPremiumRestore.value}".debugPrint();
      return null;
    }, const []);

    return Scaffold(
      appBar: settings.settingsAppBar(),
      body: Column(children: [
        Flexible(child:
          SettingsList(sections: [
            /// Time Settings Section
            SettingsSection(
              title: Text(context.timeSettings()),
              tiles: [
                settings.setTimeTile(key: 'wait', onChanged: (value) => setTime(value, 'wait')),
                settings.setTimeTile(key: 'go', onChanged: (value) => setTime(value, 'go')),
                settings.setTimeTile(key: 'flash', onChanged: (value) => setTime(value, 'flash')),
              ]
            ),
            /// Sound Settings Section
            SettingsSection(
              title: Text(context.soundSettings()),
              tiles: [
                settings.setSoundTile(onChanged: (value) => setSound(value)),
              ]
            ),
            /// Premium Plan Section (only shown for non-premium users)
            if (!isPremiumProvider) SettingsSection(
              title: Text(context.upgrade()),
              tiles: [
                settings.premiumTile(
                  premiumPrice: premiumPrice.value,
                  isReadError: isReadError.value
                ),
              ]
            ),
          ]),
        ),
        /// AdMob Banner (only shown for non-premium users)
        if (!isPremiumProvider) const AdBannerWidget()
      ])
    );
  }
}

/// Widget class that handles all settings-related UI components
/// Manages the visual presentation of time settings, sound settings, and premium plan access
class SettingsWidget {

  final BuildContext context;
  final int waitTime;
  final int goTime;
  final int flashTime;
  final bool isSound;

  SettingsWidget(this.context,{
    required this.waitTime,
    required this.goTime,
    required this.flashTime,
    required this.isSound,
  });

  /// Create the app bar for the settings page
  PreferredSize settingsAppBar() => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.settingsTitle(),
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

  /// Create time setting tile with slider control
  /// @param key Setting key (wait, go, flash)
  /// @param onChanged Callback function when time value changes
  CustomSettingsTile setTimeTile({
    required String key,
    required void Function(int) onChanged,
  }) {
    final title = {'wait': context.waitTime(), 'go': context.goTime(), 'flash': context.flashTime()};
    final time = {'wait': waitTime, 'go': goTime, 'flash': flashTime};
    final color = {'wait': transpRedColor, 'go': transpGreenColor, 'flash': transpYellowColor};
    final isTop = (key == 'wait');
    final isBottom = (key == 'flash');
    return CustomSettingsTile(
      child: Container(
        padding: EdgeInsets.only(
          top: settingsTilePaddingSize,
          bottom: isBottom ? settingsTilePaddingSize / 2: 0,
          left: settingsTilePaddingSize,
          right: settingsTilePaddingSize,
        ),
        decoration: BoxDecoration(
          color: (Platform.isIOS || Platform.isMacOS) ? whiteColor: transpColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop ? settingsTileRadiusSize: 0),
            topRight: Radius.circular(isTop ? settingsTileRadiusSize: 0),
            bottomLeft: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
            bottomRight: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.watch_later_outlined, color: grayColor),
              const SizedBox(width: 10),
              Text(title[key]!,
                style: const TextStyle(color: blackColor)
              ),
              const Spacer(),
              Text("${time[key]!}${context.timeUnit()} ", style: const TextStyle(color: blackColor)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                thumbColor: color[key]!,
                valueIndicatorColor: color[key]!,
                overlayColor: color[key]!.withAlpha(80),
                activeTrackColor: color[key]!,
                inactiveTrackColor: transpGrayColor,
                activeTickMarkColor: color[key]!,
                inactiveTickMarkColor: grayColor,
              ),
              child: Slider(
                value: time[key]!.toDouble(),
                max: maxTime.toDouble(),
                min: minTime.toDouble(),
                divisions: maxTime - minTime + 1,
                onChanged: (double value) => onChanged(value.toInt())
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create sound setting tile with switch control
  /// @param onChanged Callback function when sound setting changes
  SettingsTile setSoundTile({
    required void Function(bool) onChanged,
  }) => SettingsTile.switchTile(
    leading: const Icon(Icons.music_note),
    activeSwitchColor: transpGreenColor,
    title: Text(context.crosswalkSound()),
    initialValue: isSound,
    onToggle: (bool value) => onChanged(value),
  );

  /// Create premium plan tile with price display and upgrade navigation
  /// @param premiumPrice Current premium plan price
  /// @param isReadError Whether there was an error reading the price
  SettingsTile premiumTile({
    required String premiumPrice,
    required bool isReadError,
  }) => SettingsTile(
    title: Text(context.settingsPremiumTitle(premiumPrice, isReadError)),
    leading: premiumPrice.settingsPremiumLeadingIcon(isReadError),
    trailing: premiumPrice.settingsPremiumTrailingIcon(),
    onPressed: (context) => (premiumPrice != "") ? context.pushUpgradePage(): null,
  );
}