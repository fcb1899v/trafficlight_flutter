// The purchase page names its analytics events by where it was opened from (trial vs. settings).
// It counts a close only for the trial path.

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/analytics.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

Future<void> pumpUpgrade(WidgetTester tester, UpgradeSource source) async {
  await tester.pumpWidget(ProviderScope(
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
}
