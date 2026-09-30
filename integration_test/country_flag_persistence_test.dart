// Verifies a locale-detected flag (AU/NZ/SG/CA) survives manual style paging, both ways.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/main.dart' as app;

/// The current flag's asset path, e.g. "assets/images/pedestrian/ca/flag_ca.svg"
String? currentFlagAsset(WidgetTester tester) {
  final finder = find.byWidgetPredicate((w) =>
    w is SvgPicture && w.bytesLoader is SvgAssetLoader
    && (w.bytesLoader as SvgAssetLoader).assetName.contains('/flag_'));
  final found = finder.evaluate();
  if (found.isEmpty) return null;
  return (tester.widget<SvgPicture>(finder.first).bytesLoader as SvgAssetLoader).assetName;
}

/// Waits for the mode/back/forward buttons to all be on screen
Future<void> pumpUntilButtonsReady(WidgetTester tester, {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (find.byType(FloatingActionButton).evaluate().length < 3) {
    if (DateTime.now().isAfter(end)) fail("Timed out waiting for the mode/back/forward buttons");
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the detected flag survives manual style paging, forward and back", (tester) async {
    await app.main();
    await pumpUntilButtonsReady(tester);

    final detected = currentFlagAsset(tester);
    debugPrint("DETECTED_FLAG $detected");
    expect(detected, isNotNull, reason: "no flag SVG found on the home screen");
    // The detected flag's own style group: counters 0-1 for US-group flags (us/ca), 6 for AU-group (au/nz/sg)
    final ownGroup = detected!.contains('/us/') || detected.contains('/ca/') ? {0, 1}
      : detected.contains('/au/') || detected.contains('/nz/') || detected.contains('/sg/') ? {6}
      : detected.contains('/jp/') ? {4, 5}
      : {2, 3};
    // The style index the locale detector lands on for this group; matches groupCounter in constant.dart
    final detectedCounter = ownGroup.contains(0) ? 0: ownGroup.contains(4) ? 5: ownGroup.contains(6) ? 6: 3;
    // Counters 4-5 (Japan) show a plain red circle instead of a flag SVG; see countryFlagImage()
    String? expectedFlag(int counter) => (counter == 4 || counter == 5) ? null
      : ownGroup.contains(counter) ? detected
      : counter <= 1 ? 'assets/images/pedestrian/us/flag_us.svg'
      : counter <= 3 ? 'assets/images/pedestrian/uk/flag_uk.svg'
      : 'assets/images/pedestrian/au/flag_au.svg';

    // Full loop forward through every style, back to the start
    var counter = detectedCounter;
    for (var i = 0; i < signalNumber; i++) {
      counter = (counter + 1) % signalNumber;
      await tester.tap(find.byType(FloatingActionButton).at(2));
      await tester.pump(const Duration(milliseconds: 300));
      final flag = currentFlagAsset(tester);
      debugPrint("AFTER_FORWARD_$i counter=$counter flag=$flag");
      expect(flag, expectedFlag(counter), reason: "forward step $i (counter $counter) shows the wrong flag");
    }

    // Full loop backward through every style, back to the start
    for (var i = 0; i < signalNumber; i++) {
      counter = (counter - 1) % signalNumber;
      await tester.tap(find.byType(FloatingActionButton).at(1));
      await tester.pump(const Duration(milliseconds: 300));
      final flag = currentFlagAsset(tester);
      debugPrint("AFTER_BACK_$i counter=$counter flag=$flag");
      expect(flag, expectedFlag(counter), reason: "back step $i (counter $counter) shows the wrong flag");
    }
  });
}
