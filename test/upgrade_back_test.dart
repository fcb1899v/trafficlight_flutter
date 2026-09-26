import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/l10n/app_localizations.dart';
import 'package:signalbutton/settings.dart';
import 'package:signalbutton/upgrade.dart';

Widget screen(Widget Function(BuildContext context) builder) => MaterialApp(
  theme: ThemeData(colorScheme: const ColorScheme.light(primary: greenColor)),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Builder(builder: builder),
);

/// The upgrade page's back button, through the same placement UpgradePage uses
Widget upgradeBackScreen({required void Function() onBack}) => screen((context) => Stack(children: [
  UpgradeWidget(context, price: "", counter: 0).premiumBackLayer(onBack: onBack),
]));

/// The settings page's top bar, the screen the upgrade page is pushed from
Widget settingsBarScreen() => screen((context) => Scaffold(
  appBar: SettingsWidget(context, waitTime: 0, goTime: 0, flashTime: 0, isSound: false).settingsAppBar(),
));

final backIcon = find.byIcon(Icons.arrow_back_ios);

void main() {
  for (final (name, size, topPadding) in [
    ("667pt (iPhone SE)", const Size(375, 667), 20.0),
    ("874pt (iPhone 17 Pro)", const Size(402, 874), 62.0),
    ("1366pt (iPad Pro 13)", const Size(1024, 1366), 24.0),
  ]) {
    testWidgets("on $name the back button matches settings and keeps at least a 48x48 tap target", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = FakeViewPadding(top: topPadding);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(settingsBarScreen());
      final settingsIcon = tester.getRect(backIcon);

      var backed = false;
      await tester.pumpWidget(upgradeBackScreen(onBack: () => backed = true));
      final upgradeIcon = tester.getRect(backIcon);
      final target = tester.getRect(find.byType(IconButton));

      // The same "<" in the same place, so it does not jump when the page slides in
      expect(upgradeIcon.width, closeTo(settingsIcon.width, 0.01));
      expect(upgradeIcon.height, closeTo(settingsIcon.height, 0.01));
      expect(upgradeIcon.center.dx, closeTo(settingsIcon.center.dx, 0.01));
      expect(upgradeIcon.center.dy, closeTo(settingsIcon.center.dy, 0.01));
      // Centred on the top bar, with the full tap target
      expect(upgradeIcon.center.dy, closeTo(topPadding + size.height * 0.06 / 2, 0.01));
      expect(target.width, greaterThanOrEqualTo(kMinInteractiveDimension - 0.01));
      expect(target.height, greaterThanOrEqualTo(kMinInteractiveDimension - 0.01));
      expect(target.left, greaterThanOrEqualTo(0));
      // The shifted button still takes taps across its whole target, top edge included
      await tester.tapAt(Offset(target.center.dx, target.top + 1));
      expect(backed, isTrue);
    });
  }
}
