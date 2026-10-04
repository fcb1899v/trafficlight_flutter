// 999 finished cycles unlock the car signal for free; the count and unlock are saved and never go back.
// A purchaser is not sent cycle_unlock, and the car signal entry does not depend on the store price.

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/analytics.dart';
import 'package:signalbutton/cycle_unlock.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/plan_provider.dart';

final events = <(String, Map<String, Object>?)>[];

Future<void> start(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  await Settings.init(cacheProvider: SharePreferenceCache());
  events.clear();
  SignalAnalytics.send = (name, parameters) async => events.add((name, parameters));
}

ProviderContainer container({bool isPremium = false}) {
  final c = ProviderContainer(overrides: [
    planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: isPremium))),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  tearDown(SignalAnalytics.reset);

  test('each finished cycle adds one and is saved', () async {
    await start({});
    final c = container();
    final notifier = c.read(cycleProvider.notifier);
    expect(c.read(cycleProvider).count, 0);
    notifier.recordCycle();
    notifier.recordCycle();
    expect(c.read(cycleProvider).count, 2);
    expect("cycleCount".getSettingsValueInt(0), 2);
    expect(c.read(carSignalProvider), isFalse);
  });

  test('the 999th cycle unlocks once; the unlock is saved and survives a restart', () async {
    await start({'key_cycleCount': 998});
    final c = container();
    expect(c.read(carSignalProvider), isFalse);
    expect(c.read(cycleProvider.notifier).recordCycle(), isTrue);
    expect(c.read(cycleProvider).unlocked, isTrue);
    expect(c.read(carSignalProvider), isTrue);
    expect("cycleUnlocked".getSettingsValueBool(false), isTrue);
    expect(events.where((e) => e.$1 == 'cycle_unlock'), hasLength(1));
    // A new container reads the saved values, as a restart does
    final restarted = container();
    expect(restarted.read(cycleProvider).count, 999);
    expect(restarted.read(carSignalProvider), isTrue);
    // Later cycles keep counting, never unlock again and never lock again
    expect(restarted.read(cycleProvider.notifier).recordCycle(), isFalse);
    expect(restarted.read(cycleProvider).unlocked, isTrue);
    expect(events.where((e) => e.$1 == 'cycle_unlock'), hasLength(1));
  });

  test('the 998th cycle does not unlock', () async {
    await start({'key_cycleCount': 997});
    final c = container();
    expect(c.read(cycleProvider.notifier).recordCycle(), isFalse);
    expect(c.read(carSignalProvider), isFalse);
    expect(events.any((e) => e.$1 == 'cycle_unlock'), isFalse);
  });

  test('a purchaser who reaches 999 gets no cycle_unlock event', () async {
    await start({'key_cycleCount': 998});
    final c = container(isPremium: true);
    c.read(cycleProvider.notifier).recordCycle();
    expect(events.any((e) => e.$1 == 'cycle_unlock'), isFalse);
    expect(c.read(carSignalProvider), isTrue);
  });

  test('a purchaser enters the car signal without cycles', () async {
    await start({});
    expect(container(isPremium: true).read(carSignalProvider), isTrue);
  });

  test('an unlocked user still has isPremium false, so ads and the settings card stay', () async {
    await start({'key_cycleUnlocked': true});
    final c = container();
    expect(c.read(carSignalProvider), isTrue);
    expect(c.read(planProvider).isPremium, isFalse);
  });

  test('cycle_milestone is sent at 100, 300 and 500 with the milestone value', () async {
    await start({'key_cycleCount': 99});
    final c = container();
    final notifier = c.read(cycleProvider.notifier);
    notifier.recordCycle();
    expect(events.where((e) => e.$1 == 'cycle_milestone').map((e) => e.$2), [{'milestone': 100}]);
    for (var i = 0; i < 200; i++) {
      notifier.recordCycle();
    }
    expect(c.read(cycleProvider).count, 300);
    expect(events.where((e) => e.$1 == 'cycle_milestone').map((e) => e.$2?['milestone']), [100, 300]);
  });

  test('cycle_bucket edges line up with the milestones and the target', () {
    const expected = {
      0: '0', 1: '1-9', 9: '1-9', 10: '10-49', 49: '10-49', 50: '50-99', 99: '50-99',
      100: '100-299', 299: '100-299', 300: '300-499', 499: '300-499',
      500: '500-998', 998: '500-998', 999: '999+', 5000: '999+',
    };
    expected.forEach((count, bucket) => expect(cycleBucket(count), bucket, reason: '$count'));
  });
}
