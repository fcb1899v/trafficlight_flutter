// The purchase page shows its banner only to non-purchasers, and a purchaser's empty slot keeps the layout.

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/admob_banner.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/upgrade.dart';

/// Returns the push button's top edge, which sits below the Spacers that split the space above the ad slot
Future<double> pumpUpgrade(WidgetTester tester, {required bool isPremium}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: isPremium)))],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: UpgradePage(),
    ),
  ));
  await tester.pump(const Duration(seconds: 1));
  return tester.getRect(find.byType(Spacer).last).top;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.init(cacheProvider: SharePreferenceCache());
    PremiumPrice.reset();
  });
  tearDown(PremiumPrice.reset);

  testWidgets("purchasers see no ad on the purchase page, and the layout does not move", (tester) async {
    final freeSpacerTop = await pumpUpgrade(tester, isPremium: false);
    // Control: non-purchasers get the banner
    expect(find.byType(AdBannerWidget), findsOneWidget);
    // Unmount so the next ProviderScope starts from the purchaser state
    await tester.pumpWidget(const SizedBox());
    final premiumSpacerTop = await pumpUpgrade(tester, isPremium: true);
    expect(find.byType(AdBannerWidget), findsNothing);
    expect(premiumSpacerTop, freeSpacerTop);
  });
}
