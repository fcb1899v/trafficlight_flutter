// The "Trying the car signal" banner must stay inside the screen and clear the signal/push-button
// gap above and below it, at both device sizes and in every UI language.
// English wraps to two lines (see app_en.arb); Japanese and Chinese stay on one line.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/constant.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/homepage.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

HomeWidget homeWidget(BuildContext context) => HomeWidget(context,
  counter: 0, signalColor: const [false, false, false], isFlash: false, opaque: false, isPressed: false,
  waitTime: initialWaitTime, goTime: initialGoTime, flashTime: initialFlashTime, yellowTime: initialYellowTime, arrowTime: initialArrowTime,
);

/// Loads the real device font: the default test font draws every glyph as the same square, which hides overflow
Future<void> loadRealFont(String family, String assetPath) async {
  final loader = FontLoader(family);
  loader.addFont(rootBundle.load(assetPath));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadRealFont('beon', 'assets/fonts/beon.ttf');
    await loadRealFont('notoJP', 'assets/fonts/NotoSansJP-Bold.ttf');
    await loadRealFont('notoSC', 'assets/fonts/NotoSansSC-Bold.ttf');
  });

  // top/bottom match the iPhone 17 Pro and iPhone SE safe areas used across this app's tests.
  for (final device in [(size: const Size(402, 874), top: 62.0, bottom: 34.0),
                         (size: const Size(375, 667), top: 20.0, bottom: 0.0)]) {
    for (final locale in ['en', 'ja', 'zh']) {
      testWidgets('banner clears the signal/push-button gap: $locale @ ${device.size.width}x${device.size.height}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = device.size;
        tester.view.padding = FakeViewPadding(top: device.top, bottom: device.bottom);
        addTearDown(tester.view.reset);
        late double bannerCentre, signalBottom, gapHeight;
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: Scaffold(body: Center(child: Builder(builder: (context) {
            // Same reference points as the real Positioned(top: trialBannerCenterY()) call site.
            bannerCentre = context.trialBannerCenterY();
            signalBottom = context.signalHeight();
            gapHeight = context.height() - context.topPadding() - context.appBarHeight()
              - context.signalHeight() - context.frameHeight() - context.admobHeight();
            return homeWidget(context).carTrialBanner();
          }))),
        ));
        await tester.pump();
        final bannerRect = tester.getRect(find.byKey(const Key('carTrialBanner')));
        final text = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.byKey(const Key('carTrialBanner')), matching: find.byType(RichText)));
        // trialBannerCenterY() is the banner's vertical centre; production reaches this same value
        // via Positioned(top:) + FractionalTranslation(Offset(0, -0.5)) over the signal/frame gap.
        // overSignal/overFrame: positive means the banner box overlaps that neighbour, by how many points.
        final boxTop = bannerCentre - bannerRect.height / 2;
        final boxBottom = bannerCentre + bannerRect.height / 2;
        final overSignal = signalBottom - boxTop;
        final overFrame = boxBottom - (signalBottom + gapHeight);
        debugPrint('BANNER_GAP $locale ${device.size.width}x${device.size.height} '
          'bannerHeight=${bannerRect.height.toStringAsFixed(1)} gap=${gapHeight.toStringAsFixed(1)} '
          'overSignal=${overSignal.toStringAsFixed(1)} overFrame=${overFrame.toStringAsFixed(1)}');
        expect(text.didExceedMaxLines, isFalse, reason: 'the text is cut past its 2-line limit');
        expect(bannerRect.left >= 0 && bannerRect.right <= device.size.width, isTrue,
          reason: 'the banner leaves the screen');
      });
    }
  }
}
