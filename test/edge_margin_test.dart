// The settings and purchase pages keep their parts at the same distance from the screen's sides as the home screen: edgeMargin().

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/plan_provider.dart';
import 'package:signalbutton/settings.dart';
import 'package:signalbutton/upgrade.dart';

const sizes = [Size(375, 667), Size(402, 874), Size(1024, 1366)];

Future<void> pump(WidgetTester tester, Size size, Widget home, {TargetPlatform platform = TargetPlatform.android}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  debugDefaultTargetPlatformOverride = platform;
  await tester.pumpWidget(ProviderScope(child: MaterialApp(
    theme: ThemeData(platform: platform),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: home,
  )));
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
}

Rect decorated(WidgetTester tester, Finder within) => tester.getRect(find.descendant(of: within, matching: find.byType(DecoratedBox)).first);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.init(cacheProvider: SharePreferenceCache());
    PremiumPrice.reset();
    PremiumPrice.source = () async => '¥300';
  });
  tearDown(PremiumPrice.reset);

  for (final size in sizes) {
    testWidgets('settings: the back icon, the premium card and the list sit edgeMargin() from the sides (${size.width.toInt()} wide)', (tester) async {
      await pump(tester, size, const SettingsPage(), platform: TargetPlatform.iOS);
      final edge = tester.element(find.byType(SettingsPage)).edgeMargin();
      // On a wide screen the list is a centred column of at most 810
      final column = (size.width - size.width.clamp(0, 810)) / 2;
      final icon = tester.getRect(find.byIcon(Icons.arrow_back_ios).first);
      final card = tester.getRect(find.descendant(of: find.byType(AnimatedSize), matching: find.byWidgetPredicate((w) => w is Material && w.color == greenColor)).first);
      final tile = tester.getRect(find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == whiteColor).first);
      expect(icon.left, closeTo(edge, 0.01));
      expect(card.left, closeTo(column + edge, 0.01));
      expect(size.width - card.right, closeTo(column + edge, 0.01));
      expect(tile.left, closeTo(column + edge, 0.01));
      expect(size.width - tile.right, closeTo(column + edge, 0.01));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('purchase page: the back icon, the restore text and the two preview buttons sit edgeMargin() from the sides (${size.width.toInt()} wide)', (tester) async {
      await pump(tester, size, const UpgradePage());
      final edge = tester.element(find.byType(UpgradePage)).edgeMargin();
      final icon = tester.getRect(find.byIcon(Icons.arrow_back_ios).first);
      final restoreText = tester.getRect(find.descendant(of: find.byType(TextButton).first, matching: find.byType(Text)));
      Rect fab(String tag) => tester.getRect(find.byWidgetPredicate((w) => w is FloatingActionButton && w.heroTag == tag));
      expect(icon.left, closeTo(edge, 0.01));
      expect(restoreText.left, closeTo(edge, 0.01));
      expect(fab('back').left, closeTo(edge, 0.01));
      expect(size.width - fab('forward').right, closeTo(edge, 0.01));
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
