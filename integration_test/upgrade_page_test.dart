import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signalbutton/main.dart' as app;
import 'package:signalbutton/admob_banner.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/upgrade.dart';

/// Pumps frames until [finder] matches, without waiting for the home screen's
/// endless animations to settle
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) fail("Timed out waiting for $finder");
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Opens the upgrade page the way a user does: home, settings gear, the premium card.
/// Needs a live store price, since settings only shows the card once the price is known.
/// Optional UI language for screenshots, e.g. --dart-define=SCREENSHOT_LOCALE=ja; the device setting is left alone
const screenshotLocale = String.fromEnvironment("SCREENSHOT_LOCALE");

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the upgrade page opens from settings and holds for a screenshot", (tester) async {
    if (screenshotLocale.isNotEmpty) {
      binding.platformDispatcher.localesTestValue = [Locale(screenshotLocale)];
      addTearDown(binding.platformDispatcher.clearLocalesTestValue);
    }
    await app.main();
    await pumpUntilFound(tester, find.byIcon(Icons.settings));
    await tester.tap(find.byIcon(Icons.settings));
    // The card's forward arrow; the whole card is one tap target
    await pumpUntilFound(tester, find.byIcon(Icons.arrow_forward_ios));
    // Let the card grow in; with a screenshot locale, hold settings so the shell can take a screenshot
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // Layout in the device's real fonts: the sound switch must stay clear of the ad slot
    final switchBottom = tester.getRect(find.byWidgetPredicate(
      (w) => ['Switch', 'CupertinoSettingsSwitch'].contains(w.runtimeType.toString()))).bottom;
    final adTop = tester.getRect(find.byType(AdBannerWidget)).top;
    final cardHeight = tester.getRect(find.byWidgetPredicate((w) => w is Material && w.color == greenColor)).height;
    debugPrint("SETTINGS_LAYOUT card $cardHeight, switch bottom $switchBottom, ad top $adTop");
    debugPrint("SETTINGS_PAGE_OPEN");
    if (screenshotLocale.isNotEmpty) {
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
    await tester.tap(find.byIcon(Icons.arrow_forward_ios));
    await pumpUntilFound(tester, find.byType(UpgradePage));
    // Hold the page open so simulator screenshots can be taken from the shell
    debugPrint("UPGRADE_PAGE_OPEN");
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
    // The page shows no settings gear, and its back button returns to settings
    expect(find.descendant(of: find.byType(UpgradePage), matching: find.byIcon(Icons.settings)), findsNothing);
    await tester.tap(find.descendant(of: find.byType(UpgradePage), matching: find.byIcon(Icons.arrow_back_ios)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(UpgradePage), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
  });
}
