// The padlock's digits are drawn in beon.
// 888's ink is centred on the body, 000 (the widest) just fits, and every number keeps the same margin above and below.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

/// The body path's edges as drawn in padlock.svg, in SVG units (the outline stroke is 15, so the inner edge is 7.5 in)
const double vbLeft = padlockViewBoxLeft;
const double vbTop = padlockViewBoxTop;
const double bodyLeft = 101.1;
const double bodyRight = 402.3;
const double bodyTop = 220.49;
const double bodyBottom = 381.50;
const double halfStroke = 7.5;
const double bodyCornerRadius = 40.94;
const double scale = 8;

/// What the pixels say about one padlock, in logical px
class Measure {
  /// Ink margins to the body's inner edge
  final double left, top, right, bottom;
  /// Horizontal and vertical centres of the mode button, the body outline, the digits' ink box, and the digits' upper rounds
  final double frameX, frameY, bodyX, bodyY, inkX, inkY, roundX;
  /// The ink's left and right extent in padlock.svg units
  final double inkLeftSvg, inkRightSvg;
  Measure(this.left, this.top, this.right, this.bottom, this.frameX, this.frameY, this.bodyX, this.bodyY, this.inkX, this.inkY, this.roundX, this.inkLeftSvg, this.inkRightSvg);
}

Future<Measure> measureMargins(WidgetTester tester, int remaining) async {
  final font = FontLoader('beon')..addFont(rootBundle.load('assets/fonts/beon.ttf'));
  await font.load();
  tester.view.devicePixelRatio = scale;
  tester.view.physicalSize = const Size(402, 874) * scale;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Align(alignment: Alignment.topRight, child: Builder(builder: (context) => HomeWidget(context,
      counter: 0, signalColor: const [false, false, false], isFlash: false, opaque: false, isPressed: false,
      waitTime: initialWaitTime, goTime: initialGoTime, flashTime: initialFlashTime,
      yellowTime: initialYellowTime, arrowTime: initialArrowTime,
    ).changeIsPedestrianButton(isPedestrian: true, onPressed: () {}, isPadlock: true, padlockRemaining: remaining)))),
  )));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
  await tester.pump();
  final lock = tester.getRect(find.byKey(const Key('trialPadlock')));
  final image = (await tester.runAsync(() => (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: scale)))!;
  final bytes = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  // One SVG unit in physical pixels
  final unit = lock.height * scale / padlockViewBoxHeight;
  double px(double svg, double origin, double lockOrigin) => lockOrigin * scale + (svg - origin) * unit;
  final innerLeft = px(bodyLeft + halfStroke, vbLeft, lock.left);
  final innerRight = px(bodyRight - halfStroke, vbLeft, lock.left);
  final innerTop = px(bodyTop + halfStroke, vbTop, lock.top);
  final innerBottom = px(bodyBottom - halfStroke, vbTop, lock.top);
  // The inner edge has rounded corners (path radius less half the stroke); the black stroke beyond them is not ink
  final radius = (bodyCornerRadius - halfStroke) * unit;
  bool inside(int x, int y) {
    final dx = x < innerLeft + radius ? innerLeft + radius - x : (x > innerRight - radius ? x - (innerRight - radius) : 0.0);
    final dy = y < innerTop + radius ? innerTop + radius - y : (y > innerBottom - radius ? y - (innerBottom - radius) : 0.0);
    return dx * dx + dy * dy < (radius - 2) * (radius - 2);
  }
  var minX = 1 << 30, maxX = -1, minY = 1 << 30, maxY = -1;
  final inkPixels = <(int, int)>[];
  for (var y = innerTop.ceil(); y < innerBottom.floor(); y++) {
    for (var x = innerLeft.ceil(); x < innerRight.floor(); x++) {
      final i = (y * image.width + x) * 4;
      // Ink is the dark digit on the yellow fill
      if (inside(x, y) && bytes.getUint8(i) < 110 && bytes.getUint8(i + 1) < 110) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        inkPixels.add((x, y));
      }
    }
  }
  expect(maxX, greaterThan(0), reason: 'the digits were drawn');
  // The rounds of the 9s are the upper half of the ink; their tails run down to the left
  final roundLimit = minY + (maxY - minY) * 0.5;
  var roundMin = 1 << 30, roundMax = -1;
  for (final (x, y) in inkPixels) {
    if (y > roundLimit) continue;
    if (x < roundMin) roundMin = x;
    if (x > roundMax) roundMax = x;
  }
  // The black outline's extent on the body's middle row, and on a column clear of the shackle
  bool black(int x, int y) {
    final i = (y * image.width + x) * 4;
    return bytes.getUint8(i) < 30 && bytes.getUint8(i + 1) < 30 && bytes.getUint8(i + 2) < 30;
  }
  final midY = ((innerTop + innerBottom) / 2).round();
  var outLeft = 1 << 30, outRight = -1;
  for (var x = (lock.left * scale).floor(); x < innerLeft; x++) {
    if (black(x, midY)) { outLeft = x; break; }
  }
  for (var x = (lock.right * scale).ceil() - 1; x > innerRight; x--) {
    if (black(x, midY)) { outRight = x; break; }
  }
  final clearX = (innerRight - radius).round();
  var outTop = 1 << 30, outBottom = -1;
  for (var y = (lock.top * scale).floor(); y < (lock.bottom * scale).ceil(); y++) {
    if (!black(clearX, y)) continue;
    if (y < outTop) outTop = y;
    if (y > outBottom) outBottom = y;
  }
  final frame = tester.getRect(find.byKey(const Key('modeButton')));
  return Measure(
    (minX - innerLeft) / scale,
    (minY - innerTop) / scale,
    (innerRight - maxX - 1) / scale,
    (innerBottom - maxY - 1) / scale,
    frame.center.dx,
    frame.center.dy,
    (outLeft + outRight + 1) / 2 / scale,
    (outTop + outBottom + 1) / 2 / scale,
    (minX + maxX + 1) / 2 / scale,
    (minY + maxY + 1) / 2 / scale,
    (roundMin + roundMax + 1) / 2 / scale,
    vbLeft + (minX - lock.left * scale) / unit,
    vbLeft + (maxX + 1 - lock.left * scale) / unit,
  );
}

void main() {
  testWidgets('888 is centred on the body and the mode button', (tester) async {
    final m = await measureMargins(tester, 888);
    expect(m.inkX, closeTo(m.bodyX, 0.3));
    expect(m.bodyX, closeTo(m.frameX, 0.3));
    expect(m.left, closeTo(m.right, 0.3));
  });

  testWidgets('000, the widest, fits inside the body on both sides', (tester) async {
    final m = await measureMargins(tester, 0);
    expect(m.left, greaterThanOrEqualTo(0));
    expect(m.right, greaterThanOrEqualTo(0));
    // The body is just wide enough, so neither side has room to spare
    expect(m.left, lessThan(1));
    expect(m.right, lessThan(1));
  });

  testWidgets('every number keeps the same margin above and below and stays inside the body', (tester) async {
    for (var d = 0; d <= 9; d++) {
      final m = await measureMargins(tester, d * 111);
      expect(m.top, closeTo(2.5, 0.4), reason: '$d$d$d');
      expect(m.bottom, closeTo(2.5, 0.4), reason: '$d$d$d');
      expect(m.left, greaterThanOrEqualTo(0), reason: '$d$d$d');
      expect(m.right, greaterThanOrEqualTo(0), reason: '$d$d$d');
    }
  });
}
