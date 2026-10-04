// The home screen's mode button: a light box whose black art shows the signal a tap switches to.
// Unpurchased users see a yellow "Try" ribbon on its corner, or a yellow padlock over its art once the trial is used up.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

/// Finds an SVG picture by its asset path
Finder svgIcon(String assetName) => find.byWidgetPredicate((w) =>
  w is SvgPicture && w.bytesLoader is SvgAssetLoader && (w.bytesLoader as SvgAssetLoader).assetName == assetName);

final trafficFrame = svgIcon('assets/images/icons/traffic_signal.svg');
final walkFrame = svgIcon('assets/images/icons/pedestrian_signal.svg');
final padlock = svgIcon(padlockSvg);

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

  testWidgets("while a pedestrian cycle runs, the Try button keeps its colours and a tap still reaches it", (tester) async {
    var taps = 0;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: Align(alignment: Alignment.topRight, child: Builder(builder: (context) =>
        HomeWidget(context,
          counter: 0,
          signalColor: const [true, false, false],
          isFlash: true,
          opaque: false,
          isPressed: true,
          waitTime: initialWaitTime,
          goTime: initialGoTime,
          flashTime: initialFlashTime,
          yellowTime: initialYellowTime,
          arrowTime: initialArrowTime,
        ).changeIsPedestrianButton(isPedestrian: true, onPressed: () => taps++, isTag: true))),
      ),
    ));
    expect(artFilter(tester), isNull);
    expect(artOpacity(tester), 1.0);
    expect(tester.widget<FloatingActionButton>(find.byKey(const Key('modeButton'))).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('modeButton')));
    expect(taps, 1);
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

  testWidgets("the remaining cycles sit inside the padlock body, and the balloon stays on screen", (tester) async {
    await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(
      isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: 999, showLockBalloon: true));
    final lock = tester.getRect(padlock);
    final digits = tester.getRect(find.byKey(const Key('padlockRemaining')));
    expect(tester.widget<Text>(find.byKey(const Key('padlockRemaining'))).data, '999');
    expect(lock.contains(digits.center), isTrue);
    // The body is the lower part of the padlock, so the digits sit below the shackle
    expect(digits.center.dy, greaterThan(lock.center.dy));
    // The padlock, with its outline, stays inside the mode button's frame
    final frame = tester.getRect(find.byKey(const Key('modeButton')));
    expect(lock.left, greaterThanOrEqualTo(frame.left));
    expect(lock.right, lessThanOrEqualTo(frame.right));
    expect(lock.top, greaterThanOrEqualTo(frame.top));
    expect(lock.bottom, lessThanOrEqualTo(frame.bottom));
  });

  for (final (locale, size) in [('ja', const Size(402, 874)), ('en', const Size(402, 874)), ('zh', const Size(402, 874)), ('ja', const Size(375, 667)), ('en', const Size(375, 667)), ('zh', const Size(375, 667))]) {
    testWidgets("the balloon is two lines that do not wrap, with the count unpadded ($locale ${size.width.toInt()})", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      for (final n in [999, 88, 8, 1]) {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: Scaffold(
            floatingActionButton: Builder(builder: (context) => Container(
              margin: EdgeInsets.only(bottom: size.height * 0.4),
              child: homeWidget(context).changeIsPedestrianButton(
                isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: n, showLockBalloon: true))),
          ),
        ));
        final textFinder = find.byKey(const Key('lockBalloonText'));
        final text = tester.widget<Text>(textFinder).textSpan!.toPlainText();
        final lines = text.split('\n');
        expect(lines, hasLength(2), reason: '$n');
        // Top line: the fixed sentence; bottom line: the count with its unit, unpadded
        final bottom = switch (locale) { 'ja' => '$n 周', 'zh' => '$n 次', _ => n == 1 ? '1 cycle' : '$n cycles' };
        expect(lines[0], switch (locale) { 'ja' => '車用信号の解放まであと', 'zh' => '解锁车辆信号灯还需', _ => 'Car signal unlocks in' });
        expect(lines[1], bottom);
        // Never wraps: two lines in the paragraph, and the shrunk text stays inside the balloon
        final paragraph = tester.renderObject<RenderParagraph>(textFinder);
        final firstLine = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: lines[0].length));
        final secondLine = paragraph.getBoxesForSelection(TextSelection(baseOffset: lines[0].length + 1, extentOffset: text.length));
        // The first line sits on one level; the second sits below it and runs left to right with no wrap
        expect(firstLine.map((b) => b.bottom.round()).toSet(), hasLength(1), reason: '$n');
        expect(secondLine.every((b) => b.bottom > firstLine.first.bottom), isTrue, reason: '$n');
        for (var i = 1; i < secondLine.length; i++) {
          expect(secondLine[i].left, greaterThanOrEqualTo(secondLine[i - 1].left), reason: '$n');
        }
        final body = tester.getRect(find.byKey(const Key('lockBalloonBody')));
        {
          // The number is beon at twice the words' size
          final root = tester.widget<Text>(textFinder).textSpan! as TextSpan;
          final spans = root.children!.cast<TextSpan>();
          final number = spans.firstWhere((t) => t.text == '$n');
          final word = spans.firstWhere((t) => t.text!.contains(switch (locale) { 'ja' => '周', 'zh' => '次', _ => 'cycle' }));
          expect(word.text, switch (locale) { 'ja' => ' 周', 'zh' => ' 次', _ => n == 1 ? ' cycle' : ' cycles' }, reason: 'a half-width space between the number and the counter');
          expect(number.style!.fontFamily, 'beon');
          expect(number.style!.fontSize! / root.style!.fontSize!, closeTo(2.0, 0.001), reason: '1.5 / 0.75');
        }
        final shown = tester.getRect(textFinder);
        expect(shown.left, greaterThanOrEqualTo(body.left));
        expect(shown.right, lessThanOrEqualTo(body.right));
      }
    });
  }

  for (final (locale, size) in [('ja', const Size(402, 874)), ('en', const Size(402, 874)), ('zh', const Size(402, 874)), ('ja', const Size(375, 667)), ('en', const Size(375, 667)), ('zh', const Size(375, 667))]) {
    testWidgets("the balloon sits left of the padlock, its tail points right at it, and it stays on screen ($locale ${size.width.toInt()})", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: Scaffold(
          // Placed at mid-height on the right with the home screen's edge margin
          body: Builder(builder: (context) => Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: context.edgeMargin()),
              child: homeWidget(context).changeIsPedestrianButton(
                isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: 999, showLockBalloon: true)))),
        ),
      ));
      final button = tester.getRect(find.byKey(const Key('modeButton')));
      final body = tester.getRect(find.byKey(const Key('lockBalloonBody')));
      final tail = tester.getRect(find.byKey(const Key('lockBalloonTail')));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      // The balloon's left margin equals the button's right margin
      // The box fits its text, so Japanese and Chinese start right of the edge margin; the test font's wide English fills it.
      expect(body.left, greaterThanOrEqualTo(screen.width - button.right - 0.01));
      if (locale == 'ja' || locale == 'zh') expect(body.left, greaterThan(screen.width - button.right + 1));
      // The tail ends where the button begins, and points at the button's centre height
      expect(tail.left, closeTo(body.right, 0.01));
      expect(tail.right, closeTo(button.left, 0.01));
      expect(tail.center.dy, closeTo(button.center.dy, 0.01));
      expect(body.center.dy, closeTo(button.center.dy, 0.01));
      expect(body.top, greaterThanOrEqualTo(0));
      expect(body.bottom, lessThanOrEqualTo(screen.height));
      expect(body.right, lessThan(button.left));
    });
  }

  testWidgets("the remaining cycles are always three digits, zero-padded, in the same box", (tester) async {
    Rect? first;
    for (final (n, shown) in [(999, '999'), (88, '088'), (8, '008'), (1, '001')]) {
      await pumpModeButton(tester, (home) => home.changeIsPedestrianButton(
        isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: n));
      final digits = find.byKey(const Key('padlockRemaining'));
      expect(tester.widget<Text>(digits).data, shown);
      final lock = tester.getRect(padlock);
      expect(lock.contains(tester.getRect(digits).center), isTrue);
      final box = tester.getRect(find.ancestor(of: digits, matching: find.byType(FittedBox)));
      first ??= box;
      expect(box, first);
    }
  });
}
