// ===== SizeExt: responsive layout sizes (part of extension.dart) =====
part of 'extension.dart';

extension SizeExt on BuildContext {
  /// Device size and layout: screen dimensions and safe areas
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  /// Width basis for purchase-page sizes, capped at a share of the height so they stop growing on tablets (the share gives 460 on a 402 x 874 phone)
  double responsibleWidth() => min(width(), height() * 0.5263);

  /// Settings screen specific sizing
  double settingsListEndGap() => height() * 0.012;

  /// Settings premium card: header row sized by width, benefit rows by height.
  /// Side and base top margins match settings_ui's tile edges; an extra top and bottom margin of 1.2% of the screen height is added.
  bool _isIosSettingsStyle() => Theme.of(this).platform == TargetPlatform.iOS;
  double settingsPremiumCardOuterExtra() => height() * 0.012;
  double settingsPremiumCardOuterTop() => height() * (_isIosSettingsStyle() ? 0.016: 0.0183) + settingsPremiumCardOuterExtra();
  double settingsPremiumCardOuterBottom() => settingsPremiumCardOuterExtra();
  double settingsPremiumCardPaddingV() => height() * 0.018;
  double settingsPremiumCardPaddingH() => width() * 0.05;
  double settingsPremiumCardRadius() => height() * 0.017;
  double settingsPremiumCardIconHeight() => width() * 0.075;
  double settingsPremiumCardIconGap() => width() * 0.025;
  double settingsPremiumCardTitleFontSize() => width() * 0.048;
  double settingsPremiumCardTitlePillGap() => width() * 0.025;
  double settingsPremiumCardPriceFontSize() => width() * 0.036;
  double settingsPremiumCardPricePillPaddingH() => width() * 0.03;
  double settingsPremiumCardPricePillPaddingV() => width() * 0.008;
  double settingsPremiumCardGap() => height() * 0.012;
  double settingsPremiumCardBenefitFontSize() => height() * 0.020;
  double settingsPremiumCardCheckSize() => height() * 0.022;
  double settingsPremiumCardCheckGap() => height() * 0.006;
  double settingsPremiumCardLineGap() => height() * 0.006;
  double settingsPremiumCardArrowSize() => height() * 0.028;

  /// AdMob banner sizing
  double admobHeight() => (height() < 750) ? 50: (height() < 1000) ? 50 + (height() - 750) / 5: 100;
  double admobWidth() => width();

  /// Common UI Responsive Sizing
  double appBarHeight() => height() * 0.06;
  double appBarFontSize() => height() * (font("beon") == "beon" ? 0.036: 0.03);
  double appBarIconSize() => height() * 0.036;
  /// The icon buttons' padding around the icon, in place of the framework's fixed 8
  double iconButtonPadding() => appBarIconSize() * 0.254;
  /// The back button's tap target: the icon with its padding on each side, never under the platform's minimum tap target
  double backButtonSize() => max(kMinInteractiveDimension, appBarIconSize() + 2 * iconButtonPadding());
  /// AppBar's leading slot: from the screen's left edge to the back button's right edge
  double appBarLeadingWidth() => premiumBackCenterX() + backButtonSize() / 2;

  /// Traffic Signal Display Responsive Sizing
  double flagSize() => height() * 0.33;
  double frameHeight() => height() * 0.40;
  double signalHeight() => height() * 0.35;
  double usOldSignalFlagHeight() => height() * 0.18;

  /// Countdown Meter Responsive Sizing
  double countMeterTopSpace() => height() * 0.035;
  double countMeterCenterSpace() => height() * 0.08;
  double countDownRightPadding() => height() * 0.003;
  double countMeterWidth() => height() * 0.012;
  double countMeterHeight() => height() * 0.01;
  double countMeterSpace() => height() * 0.0024;

  /// Floating Action Button Responsive Sizing
  double floatingButtonSize() => height() * 0.07;
  double floatingButtonRadius() => floatingButtonSize() * 0.2237;
  double floatingImageSize() => floatingButtonSize() * 0.50;
  double floatingIconSize() => height() * 0.03;
  double floatingMarginBottom() => admobHeight() + floatingButtonSize() / 2;
  double modeIconHeight() => floatingButtonSize() * 0.75;
  double modePadlockHeight() => floatingButtonSize() * 0.72;
  /// The restore button's own padding, replacing the framework's fixed 12 and 8
  double restoreButtonPaddingH() => 0;
  double restoreButtonPaddingV() => height() * 0.009;
  /// The settings sections' outer margin: iOS style takes the sides from edgeMargin(); Android style keeps the package's fixed 16 inside
  /// The vertical values grow with the text size setting, as the package's own do; the last section ends with a wider gap
  EdgeInsetsDirectional settingsSectionMargin({bool isLast = false}) => _isIosSettingsStyle()
    ? EdgeInsetsDirectional.only(
        start: edgeMargin(), end: edgeMargin(),
        top: MediaQuery.textScalerOf(this).scale(height() * 0.016),
        bottom: MediaQuery.textScalerOf(this).scale(height() * (isLast ? 0.0309: 0.0114)),
      )
    : EdgeInsetsDirectional.zero;
  double settingsSectionTitleFontSize() => height() * 0.0195;
  double upgradeProgressSize() => height() * 0.0412;
  double upgradeProgressStrokeWidth() => upgradeProgressSize() * 0.111;
  /// Settings time rows
  double settingsTilePadding() => width() * 0.0498;
  double settingsTileRadius() => height() * 0.0172;
  double settingsTileIconSize() => height() * 0.0275;
  double settingsTileIconGap() => width() * 0.025;
  double settingsTileFontSize() => height() * 0.016;
  double settingsSliderTrackHeight() => height() * 0.0069;
  double settingsSliderThumbRadius() => height() * 0.0114;
  double settingsSliderOverlayRadius() => height() * 0.0275;
  /// The distance of the left, right and mode buttons and the padlock's balloon from the screen's sides; it scales with the button, as the buttons do
  double edgeMargin() => floatingButtonSize() * 0.2615;
  double modeButtonBorderWidth() => floatingButtonSize() * 0.03;

  /// Trial Ribbon Responsive Sizing
  /// Latin glyphs sit smaller than CJK glyphs at the same font size, so en gets a size boost.
  double trialRibbonFontSize() => floatingButtonSize() * (lang() == "ja" ? 0.16 : 0.20);
  double trialRibbonThickness() => trialRibbonFontSize() * 1.3;
  double trialRibbonCenter() => floatingButtonSize() * 0.198;
  double trialRibbonEdgeWidth() => premiumPlateBorderWidth();

  /// Trial Banner Responsive Sizing
  double trialBannerCenterY() => signalHeight();
  double trialBannerPaddingV() => floatingIconSize() * 0.2;
  /// The balloon's text is small so the number, drawn larger in beon, leads; every language shares the sizes
  double lockBalloonFontSize() => trialBannerFontSize() * 0.75;
  double lockBalloonDigitFontSize() => trialBannerFontSize() * 1.5;
  double trialBannerFontSize() => appBarFontSize() * (font("beon") == "beon" ? 0.80: 1.0);

  /// Upgrade Screen Responsive Sizing
  double upgradeCircularProgressMarginBottom() => height() * 0.4;

  /// Purchase Text Responsive Sizing
  double premiumTitleFontSize() => responsibleWidth() * 0.1000;
  double premiumPriceFontSize() => responsibleWidth() * 0.0957;
  double premiumBenefitFontSize() => responsibleWidth() * 0.0696;
  double premiumCaptionFontSize() => premiumBenefitFontSize();
  double premiumRestoreFontSize() => responsibleWidth() * 0.0457;
  double premiumTitleShadowBlur() => responsibleWidth() * 0.0130;

  /// Purchase page info block: title, benefit plate, price pill
  double premiumInfoGap() => responsibleWidth() * 0.0761;
  double premiumRowMaxWidth() => responsibleWidth() * 0.92;
  double premiumContentWidth() => responsibleWidth() * 0.888;
  double premiumPlatePaddingV() => responsibleWidth() * 0.0304;
  double premiumPlatePaddingH() => responsibleWidth() * 0.015;
  double premiumPlateLineGap() => responsibleWidth() * 0.0261;
  double premiumPlateRadius() => responsibleWidth() * 0.0196;
  double premiumPlateBorderWidth() => responsibleWidth() * 0.0050;
  double premiumPricePillPaddingH() => responsibleWidth() * 0.04;
  double premiumPricePillPaddingV() => responsibleWidth() * 0.0109;

  /// Purchase page "Buy" cue: a drawn arrow centred on the push button, text to its right
  double premiumGapInner() => responsibleWidth() * 0.0261;
  double premiumCueRowHeight() => responsibleWidth() * 0.1148;
  double premiumCueArrowHeight() => responsibleWidth() * 0.0678;
  double premiumCueArrowWidth() => responsibleWidth() * 0.0626;
  double premiumCueArrowGap() => premiumCaptionFontSize() * 0.227;

  /// Purchase page back button centre: the settings AppBar's leading slot and the top bar's height
  /// The back button's centre, so the icon's left edge sits edgeMargin() from the screen's left edge, unless the tap target would leave the screen
  double premiumBackCenterX() => max(edgeMargin() + appBarIconSize() / 2, backButtonSize() / 2);
  double premiumBackCenterY() => topPadding() + appBarHeight() / 2;

  /// Distance from the screen's bottom edge, clear of the real ad banner below it.
  double premiumRestoreBottom() => admobHeight() + height() * 0.01;

  /// One layer-3 Spacer(flex:1) share, from the fixed-height siblings around it (signal, frame, ad).
  /// The same split the real Column computes, so this matches the real button on every device.
  double premiumSpacerGap() =>
      (height() - topPadding() - appBarHeight() - signalHeight() - frameHeight() - admobHeight()) / 3;
  /// Screen y of the push button's top and bottom edges
  double premiumButtonTop(int counter) => topPadding() + appBarHeight()
    + premiumSpacerGap() * 2 + signalHeight() + buttonTopMargin()[counter];
  double premiumButtonBottom(int counter) =>
      premiumButtonTop(counter) + buttonHeight()[counter];
  /// Only JP new (counter 4) puts the cue below the button; every other country puts it above
  bool premiumCueBelow(int counter) => counter == 4;
  double premiumCueTop(int counter) => premiumCueBelow(counter)
    ? premiumButtonBottom(counter) + premiumGapInner()
    : premiumButtonTop(counter) - premiumGapInner() - premiumCueRowHeight();
  /// Bottom of the range the title-to-price block is centred in
  double premiumInfoAreaBottom(int counter) =>
    premiumCueBelow(counter) ? premiumButtonTop(counter) : premiumCueTop(counter);

  /// Signal-specific layout arrays, one entry per signal configuration (0-6)
  List<double> buttonHeight() => [0.13, 0.11, 0.05, 0.04, 0.115, 0.08, 0.15].map((r) => height() * r).toList();
  List<double> buttonTopMargin() => [0.225, 0.29, 0.328, 0.325, 0.143, 0.17, 0.22].map((r) => height() * r).toList();
  List<double> frameTopPadding() => [0, 0, 0, 0, 0.01, 0.02, 0].map((r) => height() * r).toList();
  List<double> frameBottomPadding() => [0, 0.08, 0, 0, 0.01, 0.02, 0].map((r) => height() * r).toList();
  List<double> labelTopMargin() => [0, 0, 0, 0, 0.085, 0.10, 0].map((r) => height() * r).toList();
  List<double> labelMiddleMargin() => [0, 0, 0, 0, 0.14, 0.135, 0].map((r) => height() * r).toList();
  List<double> labelHeight() => [0, 0, 0, 0, 0.045, 0.045, 0].map((r) => height() * r).toList();
  List<double> labelWidth() => [0, 0, 0, 0, 0.2, 0.2, 0].map((r) => height() * r).toList();
  List<double> labelFontSize() => [0, 0, 0, 0, 0.025, 0.025, 0].map((r) => height() * r).toList();
  List<double> pedestrianSignalPadding() => [0.03, 0.06, 0.03, 0.015, 0.015, 0.015, 0.015].map((r) => height() * r).toList();
  List<double> trafficSignalPadding() => [0.01, 0, 0.01, 0.01, 0.04, 0.04, 0.01].map((r) => height() * r).toList();

  /// Countdown Number Positioning
  /// Positioning arrays for countdown display elements
  List<double> cdNumTopSpace() => [0.07, 0, 0.185, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumLeftSpace() => [0.14, 0, 0.157, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumPadding() => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdNumFontSize() => [0.115, 0, 0.055, 0, 0, 0, 0].map((r) => height() * r).toList();
  List<double> cdTenLeftPadding(int countdown, bool isFlash) => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * countdown.cdTenNumber(isFlash).isOne() * r).toList();
  List<double> cdFirstLeftPadding(int countdown, bool isFlash) => [0.03, 0, 0.018, 0, 0, 0, 0].map((r) => height() * countdown.cdFirstNumber(isFlash).isOne() * r).toList();
}
