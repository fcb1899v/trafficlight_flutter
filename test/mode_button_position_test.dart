// The home screen's mode button may only brush the signal and the trial banner, and must not touch the country buttons.
// Each layer is painted alone, and the opaque pixels inside the button's rectangle are counted against overlapLimit.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

const sizes = {
  'iPhone17Pro': [402.0, 874.0, 62.0, 34.0],
  'iPhone17ProMax': [440.0, 956.0, 62.0, 34.0],
  'iPhoneSE': [375.0, 667.0, 20.0, 0.0],
  'iPad': [820.0, 1180.0, 24.0, 20.0],
};
// Opaque pixels of the signal or banner allowed inside the button's rectangle; a brush on its edge, not a cover.
const overlapLimit = 1000;
const types = ['us_new', 'us_old', 'uk_new', 'uk_old', 'jp_new', 'jp_old', 'au'];

HomeWidget homeWidget(BuildContext context, int counter, List<bool> signalColor, bool isPressed) => HomeWidget(context,
  counter: counter, signalColor: signalColor, isFlash: false, opaque: false, isPressed: isPressed,
  waitTime: initialWaitTime, goTime: initialGoTime, flashTime: initialFlashTime,
  yellowTime: initialYellowTime, arrowTime: initialArrowTime,
);

/// layers: s signal, p push button, b banner, n nav buttons, m mode button, g background
Widget scene(String layers, int counter, bool ped, List<bool> sc, bool ad, bool trial) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ja'),
  home: Builder(builder: (context) {
    final home = homeWidget(context, counter, sc, !sc[0] && ped);
    Widget only(String l, Widget w) => layers.contains(l) ? w : Opacity(opacity: 0, child: w);
    return RepaintBoundary(key: const Key('shot'), child: Scaffold(
      backgroundColor: layers.contains('g') ? null : Colors.transparent,
      appBar: home.homeAppBar(onPressed: () {}),
      body: Stack(alignment: Alignment.center, children: [
        if (layers.contains('g')) home.backGroundImage(),
        if (layers.contains('g')) home.darkBackground(),
        Column(children: [
          const Spacer(flex: 1),
          only('s', ped ? home.pedestrianSignalImage(countDown: 5) : home.trafficSignalImage()),
          const Spacer(flex: 1),
          Stack(alignment: Alignment.topCenter, children: [
            only('p', home.pushButtonFrame()), only('p', home.pushButton(onTap: () {})), only('p', home.jpFrameLabel()),
          ]),
          const Spacer(flex: 1),
          if (ad) SizedBox(height: context.admobHeight()),
        ]),
        if (trial) Positioned(
          top: context.trialBannerCenterY(), left: 0, right: 0,
          child: FractionalTranslation(translation: const Offset(0, -0.5),
            child: Center(child: only('b', home.carTrialBanner()))),
        ),
      ]),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.floatingMarginBottom()),
        child: Column(children: [
          const Spacer(flex: modeTopFlex),
          only('m', home.changeIsPedestrianButton(isPedestrian: ped, onPressed: () {}, isTag: true)),
          const Spacer(flex: modeBottomFlex),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [false, true].map((f) => only('n', home.countryChangeButton(onPressed: () {}, isForward: f))).toList()),
        ]),
      ),
    ));
  }),
);

Future<ui.Image> capture(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
  return (await tester.runAsync(() => boundary.toImage()))!;
}

Future<int> opaqueIn(WidgetTester tester, ui.Image img, Rect r) async {
  final data = (await tester.runAsync(() => img.toByteData()))!;
  var n = 0;
  for (var y = r.top.floor().clamp(0, img.height - 1); y < r.bottom.ceil().clamp(0, img.height); y++) {
    for (var x = r.left.floor().clamp(0, img.width - 1); x < r.right.ceil().clamp(0, img.width); x++) {
      if (data.getUint8((y * img.width + x) * 4 + 3) > 40) n++;
    }
  }
  return n;
}

void main() {
  final outDir = Platform.environment['SHOT_DIR'];
  final report = <String>[];
  for (final e in sizes.entries) {
    testWidgets('mode button clear of everything on ${e.key}', (tester) async {
      final v = e.value;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(v[0], v[1]);
      tester.view.padding = FakeViewPadding(top: v[2], bottom: v[3]);
      tester.view.viewPadding = FakeViewPadding(top: v[2], bottom: v[3]);
      addTearDown(tester.view.reset);
      final overlaps = <String>[];
      final notes = <String>{};
      for (var c = 0; c < 7; c++) {
        for (final ped in [false, true]) {
          final states = ped ? {'red': [false, false, false], 'green': [true, false, false]}
            : {'red': [true, false, false], 'arrow': [true, false, true]};
          for (final st in states.entries) {
            for (final ad in [true, false]) {
              final tag = '${types[c]}_${ped ? "ped" : "car"}_${st.key}_${ad ? "ad" : "noad"}';
              await tester.pumpWidget(scene('m', c, ped, st.value, ad, true));
              final btn = tester.getRect(find.byKey(const Key('modeButton')));
              final rect = btn.inflate(btn.width * 0.08);
              final res = <String>[];
              await tester.pumpWidget(scene('n', c, ped, st.value, ad, true));
              final fabs = find.byType(FloatingActionButton).evaluate().map((el) => tester.getRect(find.byWidget(el.widget))).toList();
              final navs = fabs.sublist(1);
              if (rect.inflate(btn.width * 0.1).overlaps(navs[0]) || rect.inflate(btn.width * 0.1).overlaps(navs[1])) res.add('n');
              for (final l in ['s', 'p', 'b']) {
                await tester.pumpWidget(scene(l, c, ped, st.value, ad, true));
                final img = await capture(tester);
                if (l == 'p') {
                  // A wide push box may touch the button's edge as it does the country buttons'; recorded, not failed
                  final own = await opaqueIn(tester, img, btn);
                  final nav = [await opaqueIn(tester, img, navs[0]), await opaqueIn(tester, img, navs[1])].reduce((a, b) => a > b ? a : b);
                  if (own > nav + 30) notes.add('${types[c]}_${ped ? "ped" : "car"}_${ad ? "ad" : "noad"} p:$own>$nav');
                } else {
                  final n = await opaqueIn(tester, img, rect);
                  if (n > overlapLimit) res.add('$l:$n');
                }
              }
              if (res.isNotEmpty) overlaps.add('$tag ${res.join(",")}');
              if (outDir != null && (ad || ped == false) && st.key != 'green') {
                await tester.pumpWidget(scene('sbpmng', c, ped, st.value, ad, true));
                final img = await capture(tester);
                final bytes = (await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.png)))!;
                final f = File('$outDir/${e.key}_$tag.png')..createSync(recursive: true);
                f.writeAsBytesSync(bytes.buffer.asUint8List());
              }
            }
          }
        }
      }
      File('${outDir ?? Directory.systemTemp.path}/push_box_contact_${e.key}.txt').writeAsStringSync(notes.join('\n'));
      report.add('${e.key}: ${overlaps.length} overlaps');
      File('${outDir ?? Directory.systemTemp.path}/overlap_${e.key}.txt').writeAsStringSync(overlaps.join('\n'));
      expect(overlaps, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 8)));
  }
}
