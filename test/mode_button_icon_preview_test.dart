// Draws the real mode button in its four states at real size and keeps them as a golden PNG for review.
// The states: purchaser (pedestrian and car art), "Try" ribbon, and padlock.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

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

Widget cell(Widget button) => Padding(padding: const EdgeInsets.all(8), child: SizedBox(width: 64, child: button));

void main() {
  testWidgets('the mode button in every state, at real size', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(402, 874) * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(backgroundColor: const Color(0xFFC8C8C8), body: Center(
        child: Builder(builder: (context) {
          final home = homeWidget(context);
          return Row(key: const Key('preview'), mainAxisSize: MainAxisSize.min, children: [
            cell(home.changeIsPedestrianButton(isPedestrian: false, onPressed: () {})),
            cell(home.changeIsPedestrianButton(isPedestrian: true, onPressed: () {})),
            cell(home.changeIsPedestrianButton(isPedestrian: true, onPressed: () {}, isTag: true)),
            cell(home.changeIsPedestrianButton(isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: 999)),
          ]);
        }),
      )),
    ));
    // The SVGs decode off the test's fake clock, so let real time pass before drawing
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    await expectLater(find.byKey(const Key('preview')), matchesGoldenFile('goldens/mode_button_icon_preview.png'));
  });
}
