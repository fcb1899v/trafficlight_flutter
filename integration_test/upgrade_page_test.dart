import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signalbutton/main.dart' as app;
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

/// Opens the upgrade page the way a user does: home, settings gear, the premium tile.
/// Needs a live store price, since settings only shows the tile once the price is known.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the upgrade page opens from settings and holds for a screenshot", (tester) async {
    await app.main();
    await pumpUntilFound(tester, find.byIcon(Icons.settings));
    await tester.tap(find.byIcon(Icons.settings));
    await pumpUntilFound(tester, find.byIcon(Icons.shopping_cart_outlined));
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
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
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });
}
