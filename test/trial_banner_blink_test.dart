// The "Trying the car signal" banner blinks continuously while the trial runs, using the same
// cycle and curve as the purchase page's "Buy" cue (cueOpacity), but it never stops after 5 cycles.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/upgrade.dart';

/// Mirrors HomePage's gating: repeat while [trialActive] and motion is not reduced, otherwise rest at full opacity
Future<Animation<double>> pumpBannerBlink(WidgetTester tester, {required bool trialActive, required bool reduceMotion}) async {
  late Animation<double> opacity;
  await tester.pumpWidget(HookBuilder(builder: (context) {
    final blink = useAnimationController(duration: cueBlinkCycle);
    useEffect(() {
      if (trialActive && !reduceMotion) {
        blink.repeat();
      } else {
        blink.stop();
        blink.value = 0;
      }
      return null;
    }, [trialActive, reduceMotion]);
    opacity = cueOpacity(blink);
    return const SizedBox();
  }));
  return opacity;
}

void main() {
  testWidgets("the banner keeps blinking past 5 seconds, unlike the purchase page's cue", (tester) async {
    final opacity = await pumpBannerBlink(tester, trialActive: true, reduceMotion: false);
    await tester.pump(cueBlinkTotal);
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacity.value, closeTo(0.0, 1e-6), reason: "still mid-blink well after the cue would have stopped");
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets("with reduced motion the banner stays fully visible and does not animate", (tester) async {
    final opacity = await pumpBannerBlink(tester, trialActive: true, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacity.value, closeTo(1.0, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets("once the trial is not active, the banner rests fully visible", (tester) async {
    final opacity = await pumpBannerBlink(tester, trialActive: false, reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacity.value, closeTo(1.0, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
