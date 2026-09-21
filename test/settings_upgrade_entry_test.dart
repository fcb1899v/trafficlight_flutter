// The settings "Upgrade" entry is drawn only from a live store price, with no "Loading..." row.
// It appears as soon as the price arrives.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/settings.dart';

Future<void> pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: SettingsPage(),
    ),
  ));
  await tester.pump(const Duration(seconds: 5));
}

final upgradeEntry = find.text("Premium Plan");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.init(cacheProvider: SharePreferenceCache());
    PremiumPrice.reset();
  });
  tearDown(PremiumPrice.reset);

  testWidgets("no price: no upgrade entry and no loading row", (tester) async {
    PremiumPrice.source = () async => null;
    await pumpSettings(tester);
    expect(upgradeEntry, findsNothing);
    expect(find.text("Upgrade"), findsNothing);
    // Control: the rest of the settings were drawn
    expect(find.text("Sound Settings"), findsOneWidget);
  });

  testWidgets("price: the upgrade entry is drawn", (tester) async {
    PremiumPrice.source = () async => "¥300";
    await pumpSettings(tester);
    expect(upgradeEntry, findsOneWidget);
  });

  testWidgets("a price arriving while settings are open brings the entry in", (tester) async {
    final store = Completer<String?>();
    PremiumPrice.source = () => store.future;
    await pumpSettings(tester);
    expect(upgradeEntry, findsNothing);
    store.complete("¥300");
    await tester.pump(const Duration(seconds: 5));
    expect(upgradeEntry, findsOneWidget);
  });
}
