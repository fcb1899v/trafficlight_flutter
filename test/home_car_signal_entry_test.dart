// The mode button follows carSignalProvider (bought or unlocked by 999 cycles), not the store price; cycles count once the trial is used up.
// The padlock draws the remaining count; two taps show a balloon, the third opens the purchase page, and leaving the screen resets the taps.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/admob_banner.dart';
import 'package:signalbutton/analytics.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/cycle_unlock.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/main.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

final modeButton = find.byKey(const Key('modeButton'));
final ribbon = find.byKey(const Key('trialRibbon'));
final padlock = find.byKey(const Key('trialPadlock'));
final banner = find.byKey(const Key('carTrialBanner'));
final pushButtonBox = find.ancestor(
  of: find.byWidgetPredicate((w) =>
    w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('button_us_new_o')),
  matching: find.byType(GestureDetector),
).last;

/// Presses the push button through its own handler; a screen tap lands on the frame image drawn under it in a test
Future<void> pressPushButton(WidgetTester tester) async {
  final onTap = tester.widget<GestureDetector>(pushButtonBox).onTap;
  expect(onTap, isNotNull);
  onTap!();
  await tester.pump();
}
final balloon = find.byKey(const Key('lockBalloon'));
final remaining = find.byKey(const Key('padlockRemaining'));
final events = <String>[];
const padlockCloses = maxTrialPaywallCloseCount;

/// Taps the padlock and lets its swing end
Future<void> tapLock(WidgetTester tester) async {
  await tester.tap(modeButton);
  // The first frame only starts the swing's clock
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

Future<ProviderContainer> pumpHome(WidgetTester tester, {
  int cycles = 0, bool unlocked = false, bool isPremium = false, String price = r'$3.49', int closes = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    'flutter.key_cycleCount': cycles,
    'flutter.key_cycleUnlocked': unlocked,
    'flutter.key_trialPaywallCloseCount': closes,
  });
  await Settings.init(cacheProvider: SharePreferenceCache());
  PremiumPrice.reset();
  PremiumPrice.source = () async => price.isEmpty ? null: price;
  PremiumPrice.value.value = price;
  events.clear();
  SignalAnalytics.send = (name, parameters) async => events.add(name);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: isPremium))),
    isSoundProvider.overrideWith(() => IsSoundNotifier(false)),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: HomePage(),
    ),
  ));
  // Past the price prefetch delay, so no timer is left pending
  await tester.pump(pricePrefetchDelay + const Duration(seconds: 1));
  return container;
}

/// Runs one full cycle on the default times (wait 8 + go 8 + flash 8 seconds) and a margin
Future<void> finishCycle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Every plugin the home screen touches answers with nothing
    for (final name in ['xyz.luan/audioplayers', 'com.ryanheise.just_audio.methods', 'flutter_tts', 'vibration', 'devicelocale']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });
  tearDown(() {
    PremiumPrice.reset();
    SignalAnalytics.reset();
  });

  testWidgets('without the car signal and with a price, the mode button wears the Try ribbon', (tester) async {
    await pumpHome(tester);
    expect(ribbon, findsOneWidget);
  });

  testWidgets('a cycle that unlocks at 999 turns the ribbon into a plain button and sends cycle_unlock once', (tester) async {
    final c = await pumpHome(tester, cycles: 998, closes: padlockCloses);
    expect(tester.widget<Text>(remaining).data, '001');
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 999);
    expect(modeButton, findsOneWidget);
    expect(ribbon, findsNothing);
    expect(padlock, findsNothing);
    expect(events.where((e) => e == 'cycle_unlock'), hasLength(1));
  });

  testWidgets('an unlocked user keeps the mode button with no price, while a locked one has none', (tester) async {
    await pumpHome(tester, unlocked: true, price: '');
    expect(modeButton, findsOneWidget);
    expect(ribbon, findsNothing);
    expect(padlock, findsNothing);
    await pumpHome(tester, price: '');
    expect(modeButton, findsNothing);
  });

  testWidgets('an unlocked user taps the mode button straight into car mode', (tester) async {
    await pumpHome(tester, unlocked: true);
    expect(find.byType(UpgradePage), findsNothing);
    await tester.tap(modeButton);
    await tester.pump();
    expect(banner, findsNothing);
    expect(find.byType(UpgradePage), findsNothing);
  });

  testWidgets('the ad stays for an unlocked user and goes for a purchaser', (tester) async {
    await pumpHome(tester, unlocked: true);
    expect(find.byType(AdBannerWidget), findsOneWidget);
    await pumpHome(tester, isPremium: true);
    expect(find.byType(AdBannerWidget), findsNothing);
  });

  testWidgets('while the Try ribbon shows, no cycle counts, and the trial cycle does not either', (tester) async {
    final c = await pumpHome(tester);
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 0);
    await tester.tap(modeButton);
    await tester.pump();
    expect(banner, findsOneWidget);
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 0);
    expect(find.byType(UpgradePage), findsOneWidget);
  });

  testWidgets('the padlock starts at 999 and each finished cycle after it takes one off', (tester) async {
    final c = await pumpHome(tester, closes: padlockCloses);
    expect(padlock, findsOneWidget);
    expect(tester.widget<Text>(remaining).data, '999');
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 1);
    expect(tester.widget<Text>(remaining).data, '998');
  });

  testWidgets('with no store price there is no padlock, but cycles still count once the trial is used up', (tester) async {
    final c = await pumpHome(tester, closes: padlockCloses, price: '');
    expect(padlock, findsNothing);
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 1);
  });

  testWidgets('with no store price and the trial not used up, cycles do not count', (tester) async {
    final c = await pumpHome(tester, price: '');
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 0);
  });

  testWidgets('a user already past the trial counts from this launch', (tester) async {
    await pumpHome(tester, closes: padlockCloses + 3);
    expect(tester.widget<Text>(remaining).data, '999');
  });

  testWidgets('the first two padlock taps show the balloon after the swing, and the third opens the purchase page', (tester) async {
    await pumpHome(tester, cycles: 41, closes: padlockCloses);
    expect(balloon, findsNothing);
    await tester.tap(modeButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(balloon, findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(balloon, findsOneWidget);
    expect(find.text('Car signal unlocks in\n958 cycles'), findsOneWidget);
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    expect(find.byType(UpgradePage), findsNothing);
    await tapLock(tester);
    expect(find.byType(UpgradePage), findsOneWidget);
    expect(balloon, findsNothing);
  });

  testWidgets('the English balloon says "1 cycle" when one is left', (tester) async {
    await pumpHome(tester, cycles: 998, closes: padlockCloses);
    await tapLock(tester);
    expect(find.text('Car signal unlocks in\n1 cycle'), findsOneWidget);
  });

  testWidgets('the balloon goes by itself after a few seconds', (tester) async {
    await pumpHome(tester, closes: padlockCloses);
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(balloon, findsNothing);
  });

  testWidgets('visiting settings sets the tap count back to 0', (tester) async {
    await pumpHome(tester, closes: padlockCloses);
    await tapLock(tester);
    await tapLock(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump(const Duration(seconds: 1));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(seconds: 1));
    // Two more taps would have been the third and opened the page; now it is the first
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    expect(find.byType(UpgradePage), findsNothing);
  });

  testWidgets('while the Try ribbon shows, a trial cut off by the background counts no cycle and opens no paywall', (tester) async {
    final c = await pumpHome(tester, cycles: 5);
    await tester.tap(modeButton);
    await tester.pump();
    await pressPushButton(tester);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(banner, findsNothing);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 5);
    expect(find.byType(UpgradePage), findsNothing);
  });

  testWidgets('going to the background sets the padlock tap count back to 0', (tester) async {
    await pumpHome(tester, closes: padlockCloses);
    await tapLock(tester);
    await tapLock(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(balloon, findsNothing);
    // Without the reset this would be the third tap and open the page
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    expect(find.byType(UpgradePage), findsNothing);
  });

  testWidgets('the next tap hides the balloon at once, before the swing ends', (tester) async {
    await pumpHome(tester, closes: padlockCloses);
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    await tester.tap(modeButton);
    await tester.pump();
    expect(balloon, findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(balloon, findsOneWidget);
  });

  testWidgets('after the purchase page opened from the padlock is closed, the taps count again from 0', (tester) async {
    await pumpHome(tester, closes: padlockCloses);
    await tapLock(tester);
    await tapLock(tester);
    await tapLock(tester);
    expect(find.byType(UpgradePage), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(seconds: 1));
    await tapLock(tester);
    expect(balloon, findsOneWidget);
    expect(find.byType(UpgradePage), findsNothing);
    await tapLock(tester);
    expect(find.byType(UpgradePage), findsNothing);
    await tapLock(tester);
    expect(find.byType(UpgradePage), findsOneWidget);
  });

  testWidgets('pressing the button again mid-cycle adds only one cycle', (tester) async {
    final c = await pumpHome(tester, cycles: 5, closes: padlockCloses);
    await pressPushButton(tester);
    await tester.pump(const Duration(seconds: 3));
    await pressPushButton(tester);
    await finishCycle(tester);
    expect(c.read(cycleProvider).count, 6);
  });

  for (final size in [const Size(375, 667), const Size(402, 874), const Size(820, 1180)]) {
    testWidgets('the left, right and mode buttons keep the same distance from the sides, and the balloon stays inside it (${size.width.toInt()} wide)', (tester) async {
      await pumpHome(tester, closes: padlockCloses);
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tapLock(tester);
      Rect rectOf(String tag) => tester.getRect(find.byWidgetPredicate((w) => w is FloatingActionButton && w.heroTag == tag));
      final back = rectOf('back'), forward = rectOf('forward'), mode = rectOf('mode');
      final body = tester.getRect(find.byKey(const Key('lockBalloonBody')));
      final tail = tester.getRect(find.byKey(const Key('lockBalloonTail')));
      final margin = size.width - forward.right;
      expect(back.left, closeTo(margin, 0.01));
      expect(size.width - mode.right, closeTo(margin, 0.01));
      // The balloon fits its text, so it never starts left of the edge margin
      expect(body.left, greaterThanOrEqualTo(margin - 0.01));
      // The tail meets the mode button, and the margin scales with the button
      expect(tail.right, closeTo(mode.left, 0.01));
      expect(margin / forward.width, closeTo(0.2615, 0.001));
    });
  }
}
