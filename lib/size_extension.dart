// ===== SizeExt: responsive layout sizes (part of extension.dart) =====
part of 'extension.dart';

extension SizeExt on BuildContext {
  /// Device size and layout: screen dimensions and safe areas
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  
  // Settings screen specific sizing
  double settingsSidePadding() => width() < 600 ? 10: width() / 2 - 290;
  
  // AdMob banner sizing based on screen height
  double admobHeight() => (height() < 750) ? 50: (height() < 1000) ? 50 + (height() - 750) / 5: 100;
  double admobWidth() => width();

  /// Common UI Sizing
  /// Responsive sizing for common UI elements based on screen height
  double appBarHeight() => height() * 0.06;
  double appBarFontSize() => height() * (font() == "beon" ? 0.036: 0.03);
  double appBarIconSize() => height() * 0.036;
  /// AppBar's leading slot: the framework default, widened on tall bars (iPad) so the icon keeps its size
  double appBarLeadingWidth() => appBarHeight() > kToolbarHeight ? appBarHeight(): kToolbarHeight;

  /// Signal Display Sizing
  /// Responsive sizing for traffic signal elements
  double flagSize() => height() * 0.33;
  double frameHeight() => height() * 0.40;
  double signalHeight() => height() * 0.35;
  double usOldSignalFlagHeight() => height() * 0.18;
  
  /// Countdown Meter Sizing
  /// Sizing for countdown display elements
  double countMeterTopSpace() => height() * 0.035;
  double countMeterCenterSpace() => height() * 0.08;
  double countDownRightPadding() => height() * 0.003;
  double countMeterWidth() => height() * 0.012;
  double countMeterHeight() => height() * 0.01;
  double countMeterSpace() => height() * 0.0024;
  
  /// Floating Action Button Sizing
  /// Sizing for floating action buttons and related elements
  double floatingButtonSize() => height() * 0.07;
  double floatingImageSize() => height() * 0.02;
  double floatingIconSize() => height() * 0.03;
  double floatingMarginBottom() => admobHeight() + floatingButtonSize() / 2;
  
  /// Upgrade Screen Sizing
  double upgradeCircularProgressMarginBottom() => height() * 0.4;

  /// Purchase page text (see 08_Designer/ui/2026-09-26_signal_premium_overlay_brushup.md)
  double premiumTitleFontSize() => height() * 0.046;
  double premiumPriceFontSize() => height() * 0.044;
  double premiumBenefitFontSize() => height() * 0.032;
  double premiumCaptionFontSize() => height() * 0.036;
  double premiumRestoreFontSize() => height() * 0.021;
  double premiumTitleShadowBlur() => height() * 0.006;

  /// Purchase page info block: title, benefit plate, price pill
  double premiumInfoGap() => height() * 0.035;
  double premiumRowMaxWidth() => width() * 0.92;
  double premiumContentWidth() => width() * 0.888;
  double premiumPlatePaddingV() => height() * 0.014;
  double premiumPlatePaddingH() => width() * 0.015;
  double premiumPlateLineGap() => height() * 0.012;
  double premiumPlateRadius() => height() * 0.009;
  double premiumPlateBorderWidth() => height() * 0.0023;
  double premiumPricePillPaddingH() => width() * 0.04;
  double premiumPricePillPaddingV() => height() * 0.005;

  /// Purchase page "Buy" cue: a drawn arrow centred on the push button, text to its right
  double premiumGapInner() => height() * 0.012;
  double premiumCueRowHeight() => height() * 0.0528;
  double premiumCueArrowHeight() => height() * 0.0312;
  double premiumCueArrowWidth() => height() * 0.0288;
  /// The arrow-to-text gap: the base gap plus one half-width space (0.227 em in NotoSansJP-Bold)
  double premiumCueArrowGap() => width() * 0.015 + premiumCaptionFontSize() * 0.227;
  /// The text's right edge stops short of the right country-switch FAB
  double premiumCueRightLimit() => width() - kFloatingActionButtonMargin - floatingButtonSize() - premiumGapInner();
  double premiumCueTextMaxWidth() => premiumCueRightLimit() - (width() / 2 + premiumCueArrowWidth() / 2) - premiumCueArrowGap();

  /// Purchase page back button centre: the middle of the settings AppBar's leading slot,
  /// and the top bar's vertical centre
  double premiumBackCenterX() => appBarLeadingWidth() / 2;
  double premiumBackCenterY() => topPadding() + appBarHeight() / 2;

  /// Purchase page restore link, in the bottom-left corner between the left FAB and the ad
  double premiumRestoreMaxWidth() => width() * 0.18;
  double premiumRestoreInset() => width() * 0.025;
  double premiumRestoreTop() => premiumFabRowTop() + floatingButtonSize();
  double premiumRestoreHeight() => premiumAdTop() - premiumRestoreTop();

  /// One layer-3 Spacer(flex:1) share, from the fixed-height siblings
  /// around it (signal, frame, ad); the flex values themselves are unchanged
  double premiumSpacerGap() => (height() - topPadding() - appBarHeight()
    - signalHeight() - frameHeight() - admobHeight()) / 3;
  /// Screen y of the push button's top and bottom edges
  double premiumButtonTop(int counter) => topPadding() + appBarHeight()
    + premiumSpacerGap() * 2 + signalHeight() + buttonTopMargin()[counter];
  double premiumButtonBottom(int counter) => premiumButtonTop(counter) + buttonHeight()[counter];
  /// Screen y of the country-switch FAB row's top edge and of the ad banner's top edge
  double premiumFabRowTop() => height() - floatingMarginBottom() - floatingButtonSize() - kFloatingActionButtonMargin;
  double premiumAdTop() => height() - admobHeight();
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
