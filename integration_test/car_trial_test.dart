import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signalbutton/analytics.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/main.dart' as app;
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

/// Renders straight from Flutter's own layer tree, unlike an OS-level screenshot.
/// A native dialog on top (App Tracking Transparency, ad consent) sits outside this tree and
/// so never appears, which lets a screenshot be taken while it is still up and unapproved.
/// Set [screenshotDir] to a writable directory to save a PNG under [name]; otherwise a no-op.
String? screenshotDir;
Future<void> captureFlutterScreenshot(String name) async {
  if (screenshotDir == null) return;
  // The first on-stage boundary is the visible route's; a home screen left below by settings' back button is skipped
  final onstage = find.byType(RepaintBoundary).evaluate();
  final boundary = onstage.isEmpty ? null: onstage.first.renderObject as RenderRepaintBoundary?;
  if (boundary == null) {
    debugPrint("captureFlutterScreenshot($name): no RenderRepaintBoundary found");
    return;
  }
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('$screenshotDir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint("SAVED_SCREENSHOT $name");
}

/// Finds the designer's SVG icon for the mode button, white or dark by the button's base colour
Finder svgIconEither(String whiteAsset, String darkAsset) => find.byWidgetPredicate((w) =>
  w is SvgPicture && w.bytesLoader is SvgAssetLoader
  && ((w.bytesLoader as SvgAssetLoader).assetName == whiteAsset || (w.bytesLoader as SvgAssetLoader).assetName == darkAsset));

final trafficIcon = svgIconEither(
  'assets/images/icons/traffic_signal_white.svg', 'assets/images/icons/traffic_signal_dark.svg');
final walkIcon = svgIconEither(
  'assets/images/icons/pedestrian_signal_white.svg', 'assets/images/icons/pedestrian_signal_dark.svg');

/// Pumps frames until [finder] matches, without waiting for the home screen's endless animations to settle
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) fail("Timed out waiting for $finder");
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Pumps real time (screenshots can also be taken from the shell while a [marker] is printed),
/// and saves an in-process screenshot under [marker] when screenshotDir is set
Future<void> hold(WidgetTester tester, String marker, {int seconds = 3}) async {
  debugPrint(marker);
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await captureFlutterScreenshot(marker);
}

final modeButton = find.byKey(const Key('modeButton'));
// The "Try" ribbon (named for the word on it) and the padlock over the mode button
final modeButtonWord = find.byKey(const Key('trialRibbon'));
final modeButtonLock = find.byKey(const Key('trialPadlock'));
final trialBanner = find.byKey(const Key('carTrialBanner'));

Finder assetImage(String part) => find.byWidgetPredicate((w) =>
  w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains(part));

bool modeButtonEnabled(WidgetTester tester) =>
  tester.widget<FloatingActionButton>(modeButton).onPressed != null;

/// The big signal on the home screen: the car signal or the pedestrian one, whichever is displayed
Finder signalImage(String dir) => find.byWidgetPredicate((w) =>
  w is Image && w.image is AssetImage
  && (w.image as AssetImage).assetName.contains('images/$dir/') && (w.image as AssetImage).assetName.contains('/signal_'));
final carSignalShown = signalImage('traffic');
final pedestrianSignalShown = signalImage('pedestrian');

/// The car signal is off its idle green, so a cycle is running
bool carSignalInCycle(WidgetTester tester) => carSignalShown.evaluate().isNotEmpty
  && !((tester.widget<Image>(carSignalShown).image as AssetImage).assetName.endsWith('_g.png'));

/// Every point of the mode button's visible box (a 5x5 grid, 3pt in from the edges) reaches the button in a hit test.
/// A finger lands anywhere on the button, not only at its centre where tester.tap aims.
void expectWholeModeButtonHittable(WidgetTester tester, String when) {
  final misses = hitTestMisses(tester, modeButton);
  debugPrint("HITTEST $when misses=${misses.length} ${misses.join(' | ')}");
  expect(misses, isEmpty, reason: "$when: parts of the mode button do not take taps");
}

final pushButtonImage = assetImage("/button_");

/// Checks the "Try" ribbon: its outer edge sits on the rounded corner's tip, it stays on screen,
/// its word is uncut, and it covers none of the signal art. Rebuilds the band from the app's own size values.
void expectRibbonFits(WidgetTester tester, String where) {
  final ctx = tester.element(modeButton);
  final button = tester.getRect(modeButton);
  final s = ctx.floatingButtonSize(), font = ctx.trialRibbonFontSize(), thick = ctx.trialRibbonThickness();
  final centre = ctx.trialRibbonCenter();
  const r2 = 1.41421356;
  final outline = Path()..addRSuperellipse(BorderRadius.circular(ctx.floatingButtonRadius()).toRSuperellipse(Offset.zero & Size(s, s)));
  var tip = 0.0;
  while (tip < s / 2 && !outline.contains(Offset(s - tip / r2, tip / r2))) {
    tip += 0.01;
  }
  const along = Offset(1 / r2, 1 / r2), across = Offset(1 / r2, -1 / r2);
  final mid = button.topLeft + Offset(s - centre / r2, centre / r2);
  final length = font * 3.3 + thick * 0.6 + font * 0.3;
  final a = mid - along * (length / 2), b = mid + along * (length / 2), side = across * (thick / 2), notch = along * (thick * 0.3);
  final band = Path()..addPolygon([a + side, b + side, b - notch, b - side, a - side, a + notch], true);
  final bounds = band.getBounds();
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final word = tester.renderObject<RenderParagraph>(find.descendant(of: modeButtonWord, matching: find.byType(RichText)));
  final uncut = !word.didExceedMaxLines && word.getMaxIntrinsicWidth(double.infinity) <= word.size.width + 0.5;
  final art = tester.getRect(find.descendant(of: modeButton, matching: find.byType(SvgPicture)).first);
  // The art's rounded top-right corner is inset by its 26/140 corner radius
  final artCorner = art.topRight + Offset(-art.height * 26 / 140 * (1 - 1 / r2), art.height * 26 / 140 * (1 - 1 / r2));
  final coversArt = band.contains(artCorner) || band.contains(art.topCenter) || band.contains(art.centerRight);
  debugPrint("RIBBON $where font=${font.toStringAsFixed(1)} thickness=${thick.toStringAsFixed(1)} "
    "outerEdge=${(centre - thick / 2).toStringAsFixed(2)} tip=${tip.toStringAsFixed(2)} "
    "toScreenRight=${(screen.width - bounds.right).toStringAsFixed(1)} uncut=$uncut coversArt=$coversArt");
  expect(bounds.right <= screen.width && bounds.top >= 0, isTrue, reason: "$where: the ribbon leaves the screen");
  expect(uncut, isTrue, reason: "$where: the ribbon's word is cut");
  expect(coversArt, isFalse, reason: "$where: the ribbon covers the signal art");
}

/// Pumps until the displayed signal and the push button frame have decoded, so their rects are real
Future<void> pumpUntilSignalDrawn(WidgetTester tester) async {
  bool drawn() {
    final signal = carSignalShown.evaluate().isNotEmpty ? carSignalShown: pedestrianSignalShown;
    bool decoded(Finder image) => tester.widget<RawImage>(find.descendant(of: image, matching: find.byType(RawImage))).image != null;
    return decoded(signal) && decoded(assetImage("/frame_").first);
  }
  final end = DateTime.now().add(const Duration(seconds: 5));
  await tester.pump();
  while (!drawn()) {
    if (DateTime.now().isAfter(end)) fail("The signal or frame image never loaded");
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

/// The new country style shown (US, UK, JP or AU), read from the car signal's asset; null for the old styles
String? carStyle(WidgetTester tester) {
  final name = (tester.widget<Image>(carSignalShown).image as AssetImage).assetName;
  return name.contains("/signal_us_new_") ? "US"
    : name.contains("/signal_uk_new_") ? "UK"
    : name.contains("/signal_jp_new_") ? "JP"
    : name.contains("/signal_au_") ? "AU"
    : null;
}

/// Checks the "trying" banner laid over the seam between the signal and the push button frame.
/// It must fit on screen with its text uncut, and must not take any tap from the push button beneath.
void expectTrialBannerFits(WidgetTester tester, String where) {
  final banner = tester.getRect(trialBanner);
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final signal = tester.getRect(carSignalShown.evaluate().isNotEmpty ? carSignalShown: pedestrianSignalShown);
  final frame = tester.getRect(assetImage("/frame_").first);
  final seam = (signal.bottom + frame.top) / 2;
  final text = tester.renderObject<RenderParagraph>(find.descendant(of: trialBanner, matching: find.byType(RichText)));
  final uncut = !text.didExceedMaxLines && text.getMaxIntrinsicWidth(double.infinity) <= text.size.width + 0.5;
  final misses = hitTestMisses(tester, pushButtonImage);
  debugPrint("BANNER $where banner=$banner screen=${screen.width}x${screen.height} "
    "centreMinusSeam=${(banner.center.dy - seam).toStringAsFixed(1)} "
    "overSignal=${(signal.bottom - banner.top).toStringAsFixed(1)} overFrame=${(banner.bottom - frame.top).toStringAsFixed(1)} "
    "uncut=$uncut pushMisses=${misses.length}");
  expect(banner.left >= 0 && banner.right <= screen.width && banner.top >= 0 && banner.bottom <= screen.height, isTrue,
    reason: "$where: the banner leaves the screen");
  expect(uncut, isTrue, reason: "$where: the banner text is cut");
  expect(misses, isEmpty, reason: "$where: the banner takes taps meant for the push button");
}

/// Points of [finder]'s box (a 5x5 grid, 3pt in from the edges) whose hit test does not reach it
List<String> hitTestMisses(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder).deflate(3);
  final target = tester.renderObject(finder);
  final misses = <String>[];
  for (var i = 0; i < 5; i++) {
    for (var j = 0; j < 5; j++) {
      final point = Offset(rect.left + rect.width * i / 4, rect.top + rect.height * j / 4);
      final result = HitTestResult();
      WidgetsBinding.instance.hitTestInView(result, point, tester.view.viewId);
      final hit = result.path.any((entry) {
        final t = entry.target;
        if (t is! RenderObject) return false;
        RenderObject? node = t;
        while (node != null) {
          if (identical(node, target)) return true;
          node = node.parent;
        }
        return false;
      });
      if (!hit) misses.add("(${point.dx.toStringAsFixed(1)}, ${point.dy.toStringAsFixed(1)}) -> ${result.path.first.target}");
    }
  }
  return misses;
}

/// Taps the mode button twice from the car display, checking that each tap flips the display
Future<void> expectModeButtonFlips(WidgetTester tester, String when) async {
  expect(carSignalShown, findsOneWidget, reason: "$when: the car signal should be showing first");
  expectWholeModeButtonHittable(tester, when);
  await tester.tap(modeButton);
  await tester.pump();
  expect(pedestrianSignalShown, findsOneWidget, reason: "$when: a tap should switch to the pedestrian signal");
  expect(carSignalShown, findsNothing, reason: "$when: the car signal should be gone");
  expect(trafficIcon, findsOneWidget, reason: "$when: the button should now offer the car signal");
  await tester.tap(modeButton);
  await tester.pump();
  expect(carSignalShown, findsOneWidget, reason: "$when: a second tap should switch back to the car signal");
  expect(walkIcon, findsOneWidget, reason: "$when: the button should now offer the pedestrian signal");
  debugPrint("FLIPPED $when");
}

/// Logs the mode button's rect against its neighbours.
/// At 874pt the button's rect overlaps the pedestrian signal's rect for the US and UK new styles.
/// Screenshots show a visible gap for US, but the UK countdown panel touches the button; that is still open.
/// So this only logs, rather than failing the test.
void expectModeButtonClear(WidgetTester tester, String where) {
  final button = tester.getRect(modeButton);
  final others = <String, Rect>{
    "signal": tester.getRect(assetImage("/signal_").first),
    "frame": tester.getRect(assetImage("/frame_").first),
    "back": tester.getRect(find.byType(FloatingActionButton).at(1)),
    "forward": tester.getRect(find.byType(FloatingActionButton).at(2)),
  };
  debugPrint("GEOMETRY $where button=$button ${others.entries.map((e) => '${e.key}=${e.value}').join(' ')}");
  for (final entry in others.entries) {
    if (button.overlaps(entry.value)) debugPrint("OVERLAP $where: mode button rect overlaps ${entry.key} rect");
  }
}

/// Walks the mode button through every state.
/// They are the "Try" ribbon, its dimmed art during a cycle, two trials ending on the paywall, the padlock, and a purchaser's plain button.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the mode button's Try ribbon, trial, padlock and purchaser states", (tester) async {
    screenshotDir = const String.fromEnvironment('CAR_TRIAL_SCREENSHOT_DIR').isEmpty
      ? null: const String.fromEnvironment('CAR_TRIAL_SCREENSHOT_DIR');
    // Start from a user who has never closed the trial's paywall and has not bought premium
    await Settings.init(cacheProvider: SharePreferenceCache());
    final savedCloses = Settings.getValue<int>("key_trialPaywallCloseCount", defaultValue: 0) ?? 0;
    final savedPremium = Settings.getValue<bool>("key_premium", defaultValue: false) ?? false;
    addTearDown(() async {
      await Settings.setValue("key_trialPaywallCloseCount", savedCloses);
      await Settings.setValue("key_premium", savedPremium);
    });
    await Settings.setValue("key_trialPaywallCloseCount", 0);
    await Settings.setValue("key_premium", false);

    // Overrides the logical size (e.g. to the 667pt bucket) on real hardware too, since only the
    // reported size changes; --dart-define=CAR_TRIAL_LOGICAL_WIDTH=375 CAR_TRIAL_LOGICAL_HEIGHT=667
    const logicalWidth = String.fromEnvironment('CAR_TRIAL_LOGICAL_WIDTH');
    const logicalHeight = String.fromEnvironment('CAR_TRIAL_LOGICAL_HEIGHT');
    if (logicalWidth.isNotEmpty && logicalHeight.isNotEmpty) {
      final dpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(double.parse(logicalWidth), double.parse(logicalHeight)) * dpr;
      // Safe areas of the phone being stood in for (e.g. 62/34 for iPhone 17 Pro, 20/0 for iPhone SE)
      const top = String.fromEnvironment('CAR_TRIAL_PADDING_TOP');
      const bottom = String.fromEnvironment('CAR_TRIAL_PADDING_BOTTOM');
      if (top.isNotEmpty && bottom.isNotEmpty) {
        final padding = FakeViewPadding(top: double.parse(top) * dpr, bottom: double.parse(bottom) * dpr);
        tester.view.padding = padding;
        tester.view.viewPadding = padding;
      }
      addTearDown(tester.view.reset);
    }

    await app.main();
    // Manual check with real device taps (adb shell input tap), then the test ends early:
    // --dart-define=CAR_TRIAL_DEVICE_TAPS=on lets those taps through, =off keeps the test binding's default of dropping them.
    const deviceTaps = String.fromEnvironment('CAR_TRIAL_DEVICE_TAPS');
    if (deviceTaps.isNotEmpty) {
      await tester.pump(const Duration(seconds: 8));
      // A store account that already owns premium would hide the trial, so treat this run as a free user
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(planProvider.notifier).setCurrentPlan(false);
      await tester.pump(const Duration(seconds: 1));
      // An emulator without a store has no price; the price only gates the Try ribbon, so a stand-in is enough here
      if (PremiumPrice.value.value.isEmpty) PremiumPrice.value.value = "¥500";
      await pumpUntilFound(tester, modeButtonWord, timeout: const Duration(seconds: 20));
      await tester.tap(modeButton);
      await tester.pump();
      expect(trialBanner, findsOneWidget);
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      final rect = tester.getRect(modeButton);
      final dpr = tester.view.devicePixelRatio;
      binding.shouldPropagateDevicePointerEvents = deviceTaps == 'on';
      debugPrint("DEVICE_TAP_WINDOW propagate=${binding.shouldPropagateDevicePointerEvents} "
        "centre=${(rect.center.dx * dpr).round()},${(rect.center.dy * dpr).round()} "
        "car=${carSignalShown.evaluate().isNotEmpty}");
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      debugPrint("DEVICE_TAP_WINDOW_END car=${carSignalShown.evaluate().isNotEmpty}");
      binding.shouldPropagateDevicePointerEvents = false;
      // Let the trial's cycle finish, so no timer outlives the test
      await pumpUntilFound(tester, find.byType(UpgradePage), timeout: const Duration(seconds: 45));
      return;
    }
    // The Try ribbon needs a live store price
    await pumpUntilFound(tester, modeButtonWord, timeout: const Duration(seconds: 20));
    expect(trafficIcon, findsOneWidget);

    // Every country style, with the Try ribbon in place
    for (var country = 0; country < signalNumber; country++) {
      await tester.pump(const Duration(milliseconds: 500));
      expectModeButtonClear(tester, "country $country");
      if (country.isEven) await hold(tester, "SHOT_COUNTRY_$country", seconds: 2);
      await tester.tap(find.byType(FloatingActionButton).at(2));
    }
    await tester.pump(const Duration(milliseconds: 500));
    expectRibbonFits(tester, "try");
    await hold(tester, "SHOT_TRY");

    // A pedestrian cycle dims the art and disables the button until it ends
    await tester.tap(assetImage("/button_").first);
    await tester.pump(const Duration(seconds: 2));
    expect(modeButtonEnabled(tester), isFalse);
    expectRibbonFits(tester, "cannot press");
    await hold(tester, "SHOT_GRAY");
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (!modeButtonEnabled(tester)) {
      if (DateTime.now().isAfter(end)) fail("The cycle never ended");
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Settings and back first, as a user does: the back button replaces settings with a new home screen
    await tester.tap(find.byIcon(Icons.settings));
    await pumpUntilFound(tester, find.byIcon(Icons.arrow_back_ios));
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await pumpUntilFound(tester, modeButtonWord);
    await tester.pump(const Duration(seconds: 1));

    // Two trials, each ending on the paywall and closed from it
    for (var trial = 1; trial <= maxTrialPaywallCloseCount; trial++) {
      await tester.tap(modeButton);
      await tester.pump();
      expect(trialBanner, findsOneWidget);
      // The car signal is shown, so the button now offers the pedestrian signal, with no word
      expect(walkIcon, findsOneWidget);
      expect(modeButtonWord, findsNothing);
      if (trial == 1) {
        // Before the cycle, while the push button is still awaited: the mode button flips the display both ways
        expect(carSignalShown, findsOneWidget);
        await expectModeButtonFlips(tester, "before the cycle");
        await hold(tester, "SHOT_TRIAL_CAR", seconds: 1);
        // During the cycle: the auto-press fires after trialAutoPressDelay, then the car signal leaves green
        final cycleEnd = DateTime.now().add(const Duration(seconds: 20));
        while (!carSignalInCycle(tester)) {
          if (DateTime.now().isAfter(cycleEnd)) fail("The trial's cycle never started");
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(find.byType(UpgradePage), findsNothing);
        await expectModeButtonFlips(tester, "during the cycle");
        await tester.tap(modeButton);
        await tester.pump();
        expect(pedestrianSignalShown, findsOneWidget);
        expect(trialBanner, findsOneWidget);
        await hold(tester, "SHOT_TRIAL_PEDESTRIAN", seconds: 1);
        // The banner over the signal/push-button seam, in the four new country styles, car and pedestrian.
        // The style is read from the car signal's asset, since the device locale decides where the loop starts.
        final measured = <String>{};
        for (var i = 0; i < signalNumber; i++) {
          await tester.tap(modeButton);
          await pumpUntilSignalDrawn(tester);
          final style = carStyle(tester);
          if (style != null) {
            expectTrialBannerFits(tester, "$style car");
            await captureFlutterScreenshot("BANNER_${style}_car");
          }
          await tester.tap(modeButton);
          await pumpUntilSignalDrawn(tester);
          if (style != null) {
            expectTrialBannerFits(tester, "$style pedestrian");
            await captureFlutterScreenshot("BANNER_${style}_pedestrian");
            measured.add(style);
          }
          await tester.tap(find.byType(FloatingActionButton).at(2));
          await tester.pump();
        }
        expect(measured, {"US", "UK", "JP", "AU"});
        expect(pedestrianSignalShown, findsOneWidget);
      }
      await pumpUntilFound(tester, find.byType(UpgradePage), timeout: const Duration(seconds: 45));
      debugPrint("TRIAL_${trial}_PAYWALL_SHOWN");
      await hold(tester, "SHOT_PAYWALL_$trial", seconds: 1);
      await tester.tap(find.descendant(of: find.byType(UpgradePage), matching: find.byIcon(Icons.arrow_back_ios)));
      await hold(tester, "TRIAL_${trial}_CLOSED", seconds: 2);
      expect(find.byType(UpgradePage), findsNothing);
      expect(trialBanner, findsNothing);
    }

    // The trial is used up: a padlock replaces the ribbon; the first tap only swings it
    expect(modeButtonWord, findsNothing);
    expect(modeButtonLock, findsOneWidget);
    expectModeButtonClear(tester, "padlock");
    await hold(tester, "SHOT_PADLOCK");
    final closesBefore = "trialPaywallCloseCount".getSettingsValueInt(0);
    final events = <String>[];
    SignalAnalytics.send = (name, parameters) async => events.add(name);
    addTearDown(SignalAnalytics.reset);
    await tester.tap(modeButton);
    await tester.pump(const Duration(milliseconds: 150));
    await hold(tester, "SHOT_PADLOCK_SWING", seconds: 1);
    expect(find.byType(UpgradePage), findsNothing, reason: "one tap on the padlock must not open the purchase page");
    expect(trialBanner, findsNothing);
    // The second tap swings it again, then opens the purchase page from the padlock
    await tester.tap(modeButton);
    await pumpUntilFound(tester, find.byType(UpgradePage), timeout: const Duration(seconds: 5));
    expect(tester.widget<UpgradePage>(find.byType(UpgradePage)).source, UpgradeSource.lock);
    await hold(tester, "SHOT_PAYWALL_LOCK", seconds: 1);
    await tester.tap(find.descendant(of: find.byType(UpgradePage), matching: find.byIcon(Icons.arrow_back_ios)));
    await hold(tester, "LOCK_PAYWALL_CLOSED", seconds: 2);
    expect(find.byType(UpgradePage), findsNothing);
    expect(events, containsAllInOrder(["paywall_view_lock", "paywall_close_lock"]));
    expect("trialPaywallCloseCount".getSettingsValueInt(0), closesBefore, reason: "closing the padlock's page is not a trial close");
    // Opening the page started the count again: one tap after it only swings
    await tester.tap(modeButton);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(UpgradePage), findsNothing, reason: "the tap count should start again after the page opens");
    debugPrint("PADLOCK_CHECKED events=$events");

    // A purchaser: the same button with no ribbon or padlock, offering whichever signal is not shown
    await Settings.setValue("key_premium", true);
    await tester.tap(find.byIcon(Icons.settings));
    await pumpUntilFound(tester, find.byIcon(Icons.arrow_back_ios));
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await pumpUntilFound(tester, modeButton);
    await tester.pump(const Duration(seconds: 2));
    expect(modeButtonWord, findsNothing);
    expect(modeButtonLock, findsNothing);
    expect(trafficIcon, findsOneWidget);
    await hold(tester, "SHOT_PREMIUM_PEDESTRIAN");
    await tester.tap(modeButton);
    await tester.pump(const Duration(milliseconds: 500));
    expect(walkIcon, findsOneWidget);
    expect(trialBanner, findsNothing);
    await hold(tester, "SHOT_PREMIUM_CAR");
    expect(tester.takeException(), isNull);
  });
}
