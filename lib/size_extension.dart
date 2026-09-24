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
  /// Responsive sizing for premium upgrade screen elements
  double premiumTitleFontSize() => height() * 0.035;
  double premiumPriceFontSize() => height() * 0.08;
  double premiumPricePadding() => height() * 0.025;
  double upgradeButtonFontSize() => height() * 0.025;
  double upgradeTableFontSize() => height() * 0.018;
  double upgradeTableIconSize() => height() * 0.03;
  double upgradeTableHeadingHeight() => height() * 0.03;
  double upgradeTableHeight() => height() * 0.06;
  double upgradeButtonPadding() => height() * 0.006;
  double upgradeButtonMargin() => height() * 0.05;
  double upgradeMarginWidth() => height() * 0.05;
  double upgradeCircularProgressMarginBottom() => height() * 0.4;


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
