import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signalbutton/main.dart' as app;
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

Finder assetImage(String part) => find.byWidgetPredicate((w) =>
  w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains(part));

/// The pedestrian signal's asset name, e.g. ".../signal_jp_new_r.png"
String pedestrianSignalAsset(WidgetTester tester) {
  final finder = find.byWidgetPredicate((w) => w is Image && w.image is AssetImage
    && (w.image as AssetImage).assetName.contains('images/pedestrian/') && (w.image as AssetImage).assetName.contains('/signal_'));
  if (finder.evaluate().isEmpty) return "";
  return (tester.widget<Image>(finder.first).image as AssetImage).assetName;
}

/// After a trial is cancelled by going to the background with no cycle running,
/// an ordinary press runs on the saved times, not the trial's default times.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("a press after a cancelled trial runs on the saved times", (tester) async {
    await Settings.init(cacheProvider: SharePreferenceCache());
    final savedCloses = Settings.getValue<int>("key_trialPaywallCloseCount", defaultValue: 0) ?? 0;
    final savedPremium = Settings.getValue<bool>("key_premium", defaultValue: false) ?? false;
    addTearDown(() async {
      await Settings.setValue("key_trialPaywallCloseCount", savedCloses);
      await Settings.setValue("key_premium", savedPremium);
    });
    await Settings.setValue("key_trialPaywallCloseCount", 0);
    await Settings.setValue("key_premium", false);

    await app.main();
    await tester.pump(const Duration(seconds: 8));
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    container.read(planProvider.notifier).setCurrentPlan(false);
    // Saved times (5 + 2 + 2 s) differ from the defaults (8 + 8 + 8 s)
    container.read(app.waitTimeProvider.notifier).setTime(5);
    container.read(app.goTimeProvider.notifier).setTime(2);
    container.read(app.flashTimeProvider.notifier).setTime(2);
    if (PremiumPrice.value.value.isEmpty) PremiumPrice.value.value = "¥500";
    await tester.pump(const Duration(seconds: 1));

    final modeButton = find.byKey(const Key('modeButton'));
    final trialBanner = find.byKey(const Key('carTrialBanner'));
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (find.byKey(const Key('trialRibbon')).evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) fail("The Try ribbon never showed");
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(modeButton);
    await tester.pump(const Duration(seconds: 1));
    expect(trialBanner, findsOneWidget);

    // Cancel the trial while it waits for a press (no cycle running)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(trialBanner, findsNothing);

    // An ordinary press: time it from the tap to the signal's return to red after green
    await tester.tap(assetImage("/button_").first);
    final start = DateTime.now();
    var sawGreen = false;
    final limit = start.add(const Duration(seconds: 40));
    while (true) {
      await tester.pump(const Duration(milliseconds: 250));
      final asset = pedestrianSignalAsset(tester);
      if (asset.endsWith('_g.png')) sawGreen = true;
      if (sawGreen && asset.endsWith('_r.png')) break;
      if (DateTime.now().isAfter(limit)) fail("The cycle did not end within 40 s");
    }
    final seconds = DateTime.now().difference(start).inSeconds;
    debugPrint("CANCEL_CYCLE_SECONDS $seconds");
    expect(find.byType(UpgradePage), findsNothing, reason: "an ordinary cycle must not open the paywall");
    expect(seconds, lessThan(16), reason: "the cycle ran on the default times (24 s), not the saved ones (9 s)");
    expect(tester.takeException(), isNull);
  });
}
