// The purchase page names its analytics events by where it was opened from (trial vs. settings).
// It counts a close only for the trial path.

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/analytics.dart';
import 'package:signalbutton/cycle_unlock.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

/// A plan notifier whose purchase or restore succeeds at once, so no store call is made
class _GrantingPlan extends PlanNotifier {
  @override
  Future<void> buyUpgrade(bool isRestore) async => setCurrentPlan(true);
}

Future<void> pumpUpgrade(WidgetTester tester, UpgradeSource source, {bool grants = false}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: grants ? [planProvider.overrideWith(_GrantingPlan.new)]: [],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: UpgradePage(source: source),
    ),
  ));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final events = <(String, Map<String, Object>?)>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.init(cacheProvider: SharePreferenceCache());
    PremiumPrice.reset();
    events.clear();
    SignalAnalytics.send = (name, parameters) async => events.add((name, parameters));
  });
  tearDown(() {
    PremiumPrice.reset();
    SignalAnalytics.reset();
  });

  testWidgets("opening from the trial sends paywall_view_trial once, not _settings", (tester) async {
    await pumpUpgrade(tester, UpgradeSource.trial);
    expect(events.where((e) => e.$1 == 'paywall_view_trial').length, 1);
    expect(events.any((e) => e.$1 == 'paywall_view_settings'), isFalse);
  });

  testWidgets("opening from settings sends paywall_view_settings once, not _trial", (tester) async {
    await pumpUpgrade(tester, UpgradeSource.settings);
    expect(events.where((e) => e.$1 == 'paywall_view_settings').length, 1);
    expect(events.any((e) => e.$1 == 'paywall_view_trial'), isFalse);
  });

  testWidgets("closing the trial page counts and saves the close", (tester) async {
    await pumpUpgrade(tester, UpgradeSource.trial);
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();
    final closeEvents = events.where((e) => e.$1 == 'paywall_close_trial').toList();
    expect(closeEvents, hasLength(1));
    expect(closeEvents.single.$2?['close_count'], 1);
    expect("trialPaywallCloseCount".getSettingsValueInt(0), 1);
  });

  testWidgets("closing the settings page does not count", (tester) async {
    await pumpUpgrade(tester, UpgradeSource.settings);
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pumpAndSettle();
    expect(events.any((e) => e.$1 == 'paywall_close_trial'), isFalse);
    expect(events.where((e) => e.$1 == 'paywall_close_settings').length, 1);
    expect("trialPaywallCloseCount".getSettingsValueInt(0), 0);
  });

  for (final (source, count, bucket) in [
    (UpgradeSource.trial, 0, '0'), (UpgradeSource.settings, 120, '100-299'), (UpgradeSource.lock, 999, '999+'),
  ]) {
    testWidgets("paywall_view_${source.name} carries the cycle bucket $bucket for $count cycles", (tester) async {
      SharedPreferences.setMockInitialValues({'flutter.key_cycleCount': count});
      await Settings.init(cacheProvider: SharePreferenceCache());
      await pumpUpgrade(tester, source);
      final view = events.singleWhere((e) => e.$1 == 'paywall_view_${source.name}');
      expect(view.$2, {'cycle_bucket': bucket});
      expect(bucket, cycleBucket(count));
    });
  }

  testWidgets("a purchase sends premium_purchase_<source> with the cycle bucket", (tester) async {
    SharedPreferences.setMockInitialValues({'flutter.key_cycleCount': 120, 'flutter.key_premiumPrice': r'$3.49'});
    await Settings.init(cacheProvider: SharePreferenceCache());
    await pumpUpgrade(tester, UpgradeSource.settings, grants: true);
    await tester.tap(find.text(r'$3.49'));
    await tester.pump(const Duration(seconds: 1));
    final purchase = events.singleWhere((e) => e.$1 == 'premium_purchase_settings');
    expect(purchase.$2, {'cycle_bucket': '100-299'});
  });

  testWidgets("a restore sends premium_restore_<source> without the cycle bucket", (tester) async {
    SharedPreferences.setMockInitialValues({'flutter.key_cycleCount': 120, 'flutter.key_premiumPrice': r'$3.49'});
    await Settings.init(cacheProvider: SharePreferenceCache());
    await pumpUpgrade(tester, UpgradeSource.settings, grants: true);
    await tester.tap(find.text(tester.element(find.byType(UpgradePage)).restore()));
    await tester.pump(const Duration(seconds: 1));
    final restore = events.singleWhere((e) => e.$1 == 'premium_restore_settings');
    expect(restore.$2, isNull);
  });
}
