// The home screen's mode button: a light box whose black art shows the signal a tap switches to.
// Unpurchased users see a yellow "Try" ribbon on its corner, or a yellow padlock over its art once the trial is used up.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

/// Finds an SVG picture by its asset path
Finder svgIcon(String assetName) => find.byWidgetPredicate((w) =>
  w is SvgPicture && w.bytesLoader is SvgAssetLoader && (w.bytesLoader as SvgAssetLoader).assetName == assetName);

final trafficFrame = svgIcon('assets/images/icons/traffic_signal.svg');
final walkFrame = svgIcon('assets/images/icons/pedestrian_signal.svg');
final padlock = svgIcon(padlockStar);

/// The frame's colour filter, null when it is drawn in its own black
ColorFilter? artFilter(WidgetTester tester) => tester.widget<SvgPicture>(trafficFrame).colorFilter;

/// The art's opacity: 1.0 unless an Opacity ancestor (only present behind the padlock) says otherwise
double artOpacity(WidgetTester tester) {
  final ancestor = find.ancestor(of: trafficFrame, matching: find.byType(Opacity));
  return ancestor.evaluate().isEmpty ? 1.0 : tester.widget<Opacity>(ancestor).opacity;
}

HomeWidget homeWidget(BuildContext context) => HomeWidget(context,
  counter: 0,
  signalColor: const [false, false, false],
  isFlash: false,
  opaque: false,
  isPressed: false,
  waitTime: initialWaitTime,
  goTime: initialGoTime,
  flashTime: initialFlashTime,
  yellowTime: initialYellowTime,
  arrowTime: initialArrowTime,
);

/// The mode button alone, placed at the screen's top right as on the home screen
Future<void> pumpModeButton(WidgetTester tester, Widget Function(HomeWidget home) button) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: Scaffold(body: Align(
      alignment: Alignment.topRight,
      child: Builder(builder: (context) => button(homeWidget(context))),
    )),
  ));
}

void main() {
  testWidgets("on the light base, the icon is the black SVG for the signal a tap switches to", (tester) async {
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(isPedestrian: true, onPressed: () {}));
    expect(trafficFrame, findsOneWidget);
    expect(artOpacity(tester), 1.0);
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(isPedestrian: false, onPressed: () {}));
    expect(walkFrame, findsOneWidget);
  });

  testWidgets("the Try button keeps the black art and wears the ribbon with its word; a tap on the ribbon reaches the button", (tester) async {
    var taps = 0;
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(
      isPedestrian: true, onPressed: () => taps++, isTag: true));
    expect(trafficFrame, findsOneWidget);
    expect(artFilter(tester), isNull);
    expect(find.byKey(const Key('trialRibbon')), findsOneWidget);
    expect(find.text("お試し"), findsOneWidget);
    expect(artOpacity(tester), 1.0);
    // The word sits on the ribbon over the button's corner; the ribbon ignores taps, so the button takes them
    await tester.tapAt(tester.getCenter(find.text("お試し")));
    expect(taps, 1);
  });

  testWidgets("while it cannot be pressed, only the art dims; the ribbon stays, and taps are ignored", (tester) async {
    var taps = 0;
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(
      isPedestrian: true, enabled: false, onPressed: () => taps++, isTag: true));
    expect(artFilter(tester), const ColorFilter.mode(modeIconDimColor, BlendMode.srcIn));
    expect(artOpacity(tester), 1.0);
    expect(find.byKey(const Key('trialRibbon')), findsOneWidget);
    await tester.tap(find.byKey(const Key('modeButton')));
    expect(taps, 0);
  });

  testWidgets("the padlock lies over the undimmed art with no ribbon, and a tap reaches the callback", (tester) async {
    var taps = 0;
    final swing = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 600));
    addTearDown(swing.dispose);
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(
      isPedestrian: true, onPressed: () => taps++, isPadlock: true, padlockSwing: swing));
    expect(padlock, findsOneWidget);
    expect(artFilter(tester), isNull);
    expect(artOpacity(tester), 0.8);
    expect(find.byKey(const Key('trialRibbon')), findsNothing);
    await tester.tap(find.byKey(const Key('modeButton')));
    expect(taps, 1);
  });
}
