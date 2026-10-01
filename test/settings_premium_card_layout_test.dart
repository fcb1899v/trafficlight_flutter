// With the premium card on top, the "Crosswalk sound" switch must stay at least 15pt clear of the ad slot.
// The card uses the real app fonts; settings_ui's rows and CJK glyphs stay in the test font (no family to load).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/admob_banner.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/settings.dart';

Future<void> loadRealFont(String family, String assetPath) async {
  final loader = FontLoader(family);
  loader.addFont(rootBundle.load(assetPath));
  await loader.load();
}

final card = find.byWidgetPredicate((w) => w is Material && w.color == greenColor);
// settings_ui draws its own switch types (package:material_ui's Switch on Android), so match by name
final soundSwitch = find.byWidgetPredicate(
  (w) => ['Switch', 'CupertinoSettingsSwitch'].contains(w.runtimeType.toString()));
final arrow = find.byIcon(Icons.arrow_forward_ios);

Future<BuildContext> pumpSettings(WidgetTester tester, {
  required Size size, required double top, required double bottom, required String locale, bool isPremium = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: isPremium)))],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: const SettingsPage(),
    ),
  ));
  // Price lookup, then the AnimatedSize growth
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
  return tester.element(find.byType(SettingsPage));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadRealFont('beon', 'assets/fonts/beon.ttf');
    await loadRealFont('notoJP', 'assets/fonts/NotoSansJP-Bold.ttf');
    await loadRealFont('notoSC', 'assets/fonts/NotoSansSC-Bold.ttf');
    // The app's own time rows use the theme font; Roboto Bold stands in for it so English keeps real widths
    for (final family in ['Roboto', 'CupertinoSystemText', 'CupertinoSystemDisplay']) {
      await loadRealFont(family, 'assets/fonts/Roboto-Bold.ttf');
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.init(cacheProvider: SharePreferenceCache());
    PremiumPrice.reset();
    PremiumPrice.source = () async => "R\$ 19,90";
  });
  tearDown(PremiumPrice.reset);

  // top/bottom match the iPhone 17 Pro and iPhone SE safe areas used across this app's tests.
  // cardHeight is the design spec's range, with a tolerance; null where the spec gives none.
  // checked: false skips the 15pt clearance; the scroll test below checks the sound row ends up above the ad.
  final devices = [
    (name: 'iOS 874', platform: TargetPlatform.iOS, size: const Size(402, 874), top: 62.0, bottom: 34.0, cardHeight: (124.3, 128.7), checked: true),
    (name: 'iOS 667', platform: TargetPlatform.iOS, size: const Size(375, 667), top: 20.0, bottom: 0.0, cardHeight: (99.3, 103.5), checked: false),
    (name: 'Android 360x640', platform: TargetPlatform.android, size: const Size(360, 640), top: 24.0, bottom: 0.0, cardHeight: null, checked: false),
    (name: 'Android 360x699', platform: TargetPlatform.android, size: const Size(360, 699), top: 24.0, bottom: 0.0, cardHeight: null, checked: false),
    (name: 'Android 360x700', platform: TargetPlatform.android, size: const Size(360, 700), top: 24.0, bottom: 0.0, cardHeight: null, checked: false),
    (name: 'Android 412x915', platform: TargetPlatform.android, size: const Size(412, 915), top: 24.0, bottom: 0.0, cardHeight: null, checked: true),
  ];
  for (final device in devices) {
    for (final locale in ['ja', 'en', 'zh']) {
      testWidgets('card fits and the sound switch clears the ad: $locale @ ${device.name}', (tester) async {
        final context = await pumpSettings(tester,
          size: device.size, top: device.top, bottom: device.bottom, locale: locale);
        final cardRect = tester.getRect(card);
        final switchRect = tester.getRect(soundSwitch);
        final adRect = tester.getRect(find.byType(AdBannerWidget));
        final arrowRect = tester.getRect(arrow);
        final benefitRight = [context.carSignalAvailable(), context.removeAllAds()]
          .map((text) => tester.getRect(find.text(text)).right)
          .reduce((a, b) => a > b ? a : b);
        debugPrint('${device.name} $locale: card ${cardRect.height.toStringAsFixed(1)}, '
          'switch bottom ${switchRect.bottom.toStringAsFixed(1)}, ad top ${adRect.top.toStringAsFixed(1)}, '
          'clearance ${(adRect.top - switchRect.bottom).toStringAsFixed(1)}, '
          'benefit-arrow gap ${(arrowRect.left - benefitRight).toStringAsFixed(1)}');
        // The ad slot is a fixed box at the bottom, so its top is a real limit, not the screen edge
        expect(adRect.height, greaterThanOrEqualTo(50));
        expect(adRect.bottom, device.size.height);
        if (device.checked) expect(switchRect.bottom, lessThanOrEqualTo(adRect.top - 15));
        expect(arrowRect.left - benefitRight, greaterThanOrEqualTo(context.settingsPremiumCardTitlePillGap()));
        final range = device.cardHeight;
        if (range != null) expect(cardRect.height, inInclusiveRange(range.$1, range.$2));
        // Nothing in the card overflowed
        expect(tester.takeException(), isNull);
      }, variant: TargetPlatformVariant.only(device.platform));
    }
  }
  // Scrolls to the end only where the switch starts under the ad, then it must sit above the ad slot.
  for (final device in devices.where((d) => !d.checked)) {
    for (final locale in ['ja', 'en', 'zh']) {
      testWidgets('the sound switch ends up above the ad after any needed scroll: $locale @ ${device.name}', (tester) async {
        await pumpSettings(tester, size: device.size, top: device.top, bottom: device.bottom, locale: locale);
        final adTop = tester.getRect(find.byType(AdBannerWidget)).top;
        if (tester.getRect(soundSwitch).bottom > adTop) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
          await tester.pump(const Duration(seconds: 1));
        }
        expect(tester.getRect(soundSwitch).bottom, lessThanOrEqualTo(adTop));
      }, variant: TargetPlatformVariant.only(device.platform));
    }
  }

  testWidgets('premium users see neither the card nor the ad', (tester) async {
    await pumpSettings(tester, size: const Size(402, 874), top: 62, bottom: 34, locale: 'en', isPremium: true);
    expect(card, findsNothing);
    expect(find.byType(AdBannerWidget), findsNothing);
    // Control: the rest of the settings were drawn
    expect(soundSwitch, findsOneWidget);
  });
}
