import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/upgrade.dart';

/// Pumps a bare widget that owns the purchase page's blink and exposes its opacity
Future<Animation<double>> pumpBlink(WidgetTester tester, {required bool reduceMotion}) async {
  late Animation<double> opacity;
  await tester.pumpWidget(HookBuilder(builder: (context) {
    opacity = cueOpacity(useCueBlink(reduceMotion: reduceMotion));
    return const SizedBox();
  }));
  return opacity;
}

void main() {
  testWidgets("the cue starts visible and stays visible for half a second", (tester) async {
    final opacity = await pumpBlink(tester, reduceMotion: false);
    expect(opacity.value, closeTo(1.0, 1e-9));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity.value, closeTo(1.0, 1e-6));
  });

  testWidgets("the cue is fully hidden from 0.6 s to 0.9 s", (tester) async {
    final opacity = await pumpBlink(tester, reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacity.value, closeTo(0.0, 1e-6));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity.value, closeTo(0.0, 1e-6));
  });

  testWidgets("one blink takes one second and ends visible", (tester) async {
    final opacity = await pumpBlink(tester, reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 999));
    expect(opacity.value, greaterThan(0.9));
    await tester.pump(const Duration(milliseconds: 51));
    expect(opacity.value, closeTo(1.0, 1e-6));
  });

  testWidgets("after five blinks the cue rests fully visible and stops moving", (tester) async {
    final opacity = await pumpBlink(tester, reduceMotion: false);
    await tester.pump(cueBlinkTotal);
    expect(opacity.value, closeTo(1.0, 1e-9));
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacity.value, closeTo(1.0, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });

  Future<bool> readReduceMotion(WidgetTester tester, {bool disableAnimations = false}) async {
    late bool result;
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Builder(builder: (context) {
        result = premiumReduceMotion(context);
        return const SizedBox();
      }),
    ));
    return result;
  }

  testWidgets("reduced motion is off when neither OS setting asks for it", (tester) async {
    expect(await readReduceMotion(tester), isFalse);
  });

  testWidgets("Android's remove-animations setting counts as reduced motion", (tester) async {
    expect(await readReduceMotion(tester, disableAnimations: true), isTrue);
  });

  testWidgets("iOS Reduce Motion counts as reduced motion", (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    expect(await readReduceMotion(tester), isTrue);
  });

  testWidgets("with reduced motion the cue never blinks", (tester) async {
    final opacity = await pumpBlink(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacity.value, closeTo(1.0, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
