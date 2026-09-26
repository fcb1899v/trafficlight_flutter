import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'extension.dart';
import 'constant.dart';
import 'plan_provider.dart';
import 'homepage.dart';
import 'admob_banner.dart';

// The purchase page shows new-signal styles only; the shared indices are
// US new=0, US old=1, UK new=2, UK old=3, JP new=4, JP old=5, AU=6.
const List<int> _premiumSignalCounters = [0, 2, 4, 6];

/// Maps any of the 7 shared signal-style indices to its new-style
/// equivalent (old styles fold onto the new style of the same country).
int _toNewSignalCounter(int counter) => counter.isOdd ? counter - 1: counter;

/// One blink of the "Buy" cue: shown, off and shown again within one second
const Duration cueBlinkCycle = Duration(seconds: 1);
/// The cue blinks five times, then rests fully visible
const Duration cueBlinkTotal = Duration(seconds: 5);

/// Drives the "Buy" cue's blink: each second runs 0 to 1 once (see cueOpacity).
/// It starts visible, blinks five times and rests at 0; with reduced motion it never moves.
AnimationController useCueBlink({required bool reduceMotion}) {
  final blink = useAnimationController(duration: cueBlinkCycle);
  useEffect(() {
    if (reduceMotion) return null;
    blink.repeat();
    final stop = Timer(cueBlinkTotal, () {
      blink.stop();
      blink.value = 0;
    });
    return stop.cancel;
  }, const []);
  return blink;
}

/// Whether the OS asks for less motion. iOS "Reduce Motion" does not set
/// disableAnimations, so the platform accessibility features are read too.
bool premiumReduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context)
  || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion;

/// Opacity over one blink: shown 0.5 s, off in 0.1 s, hidden 0.3 s, back in 0.1 s
Animation<double> cueOpacity(Animation<double> blink) => blink.drive(TweenSequence<double>([
  TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
  TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
  TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
]));

/// Upgrade page widget that handles premium plan purchases and restorations
/// Uses Riverpod for state management and Flutter Hooks for local state
class UpgradePage extends HookConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the plan state from the provider
    final planState = ref.watch(planProvider);
    // Read the plan notifier for actions
    final plan = ref.read(planProvider.notifier);
    // Local state for restore mode and premium price
    final isRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    // The country style (US/UK/JP/AU) the car signal and push button are drawn from
    final counter = useState(0);
    // Blinks the "Buy" cue five times so the eye finds the button, then stops
    final blink = useCueBlink(reduceMotion: premiumReduceMotion(context));
    // Create upgrade widget instance
    final upgrade = UpgradeWidget(context,
      price: premiumPrice.value,
      counter: counter.value,
    );
    /// Initialize purchase functionality and set up promoted product listener
    initPurchase() {
      Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
        'productID: $productID'.debugPrint();
        try {
          final purchaseResult = await startPurchase.call();
          'productID: ${purchaseResult.productIdentifier}'.debugPrint();
          'customerInfo: ${purchaseResult.customerInfo}'.debugPrint();
        } catch (e) {
          'Error: $e'.debugPrint();
        }
      });
      "isPremiumRestore: ${isRestore.value}".debugPrint();
    }
    // Initialize settings and purchase functionality on first frame
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        initPurchase();
        counter.value = _toNewSignalCounter(await getCountryCounter());
      });
      return;
    }, const []);
    /// Handle purchase or restore action
    /// @param isRestore Whether this is a restore operation or new purchase
    buyUpgrade(bool isRestore) async {
      // Read live, not the watched planState above: a fast second tap must see
      // the flag this call itself is about to set, not the pre-tap snapshot.
      if (ref.read(planProvider).isPurchasing) return;
      "isRestore: $isRestore".debugPrint();
      try {
        await plan.buyUpgrade(isRestore);
        upgrade.purchaseDialog(
          isSuccess: true,
          isRestore: isRestore,
        );
      } on PlatformException catch (e) {
        "Button tap error: $e".debugPrint();
        upgrade.purchaseDialog(
          isSuccess: false,
          isRestore: isRestore,
          errorCode: PurchasesErrorHelper.getErrorCode(e),
        );
      } catch (e) {
        "Button tap error: $e".debugPrint();
        upgrade.purchaseDialog(
          isSuccess: false,
          isRestore: isRestore,
        );
      }
    }

    // The home screen in car mode, built from the same HomeWidget parts
    final preview = HomeWidget(context,
      counter: counter.value,
      signalColor: const [false, false, false],
      isFlash: false,
      opaque: true,
      isPressed: false,
      waitTime: initialWaitTime,
      goTime: initialGoTime,
      flashTime: initialFlashTime,
      yellowTime: initialYellowTime,
      arrowTime: initialArrowTime,
    );
    final bodyTop = context.topPadding() + context.appBarHeight();

    return Material(
      color: blackColor,
      child: Stack(children: [
        // Layer 1: the car-signal home screen, same layout as HomePage
        Scaffold(
          // The home bar without its settings gear; the back button above the overlay leaves
          appBar: preview.homeAppBar(onPressed: null),
          body: Stack(alignment: Alignment.center, children: [
            preview.backGroundImage(),
            preview.darkBackground(),
            Column(children: [
              const Spacer(flex: 1),
              preview.trafficSignalImage(),
              const Spacer(flex: 1),
              // The push button itself sits in layer 3, above the overlay
              Stack(alignment: Alignment.topCenter, children: [
                preview.pushButtonFrame(),
                preview.jpFrameLabel(),
              ]),
              const Spacer(flex: 1),
              // The ad banner itself sits in layer 3, above the overlay
              SizedBox(height: context.admobHeight()),
            ]),
          ]),
          floatingActionButton: Container(
            margin: EdgeInsets.only(bottom: context.floatingMarginBottom()),
            child: Column(children: [
              const Spacer(flex: 3),
              const Spacer(flex: 2),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Previews the other countries' car signals, new styles only
                children: [false, true].map((isForward) => preview.countryChangeButton(
                  onPressed: () {
                    final i = _premiumSignalCounters.indexOf(counter.value);
                    counter.value = _premiumSignalCounters[
                      (i + (isForward ? 1: -1)) % _premiumSignalCounters.length];
                  },
                  isForward: isForward,
                )).toList(),
              ),
            ]),
          ),
        ),
        // Layer 2: dims the whole screen; taps pass through to layer 1.
        // Needs an explicit size: an unconstrained Container in a Stack
        // collapses to zero and would not dim anything.
        IgnorePointer(child: Container(
          width: context.width(),
          height: context.height(),
          color: premiumOverlayColor,
        )),
        // Layer 3: aligned with layer 1's body; only the push button and the
        // ad banner stay lit. The car signal slot is empty, so it stays dimmed.
        Positioned(
          top: bodyTop,
          left: 0, right: 0, bottom: 0,
          child: Column(children: [
            const Spacer(flex: 1),
            SizedBox(height: context.signalHeight()),
            const Spacer(flex: 1),
            Stack(alignment: Alignment.topCenter, children: [
              SizedBox(height: context.frameHeight()),
              preview.pushButton(onTap: () => buyUpgrade(false)),
            ]),
            const Spacer(flex: 1),
            const AdBannerWidget(),
          ]),
        ),
        // Title, benefit plate and price, centred between the top bar and the cue or button
        Positioned(
          top: bodyTop,
          left: 0, right: 0,
          height: context.premiumInfoAreaBottom(counter.value) - bodyTop,
          child: Center(child: upgrade.premiumInfo(onBuy: () => buyUpgrade(false))),
        ),
        // "Buy" cue: the arrow's centre sits on the button's centre line
        Positioned(
          left: context.width() / 2 - context.premiumCueArrowWidth() / 2,
          top: context.premiumCueTop(counter.value),
          height: context.premiumCueRowHeight(),
          child: upgrade.premiumCue(onBuy: () => buyUpgrade(false), blink: blink),
        ),
        // Restore, in the bottom-left corner between the left FAB and the ad
        Positioned(
          left: context.premiumRestoreInset(),
          top: context.premiumRestoreTop(),
          child: upgrade.premiumRestore(onRestore: () => buyUpgrade(true)),
        ),
        // Back to settings, lit above the overlay at the top bar's left end
        upgrade.premiumBackLayer(onBack: () => Navigator.pop(context)),
        // Show loading indicator during purchase process
        if (planState.isPurchasing) Center(child: upgrade.circularProgressIndicator()),
      ]),
    );
  }
}

/// Draws a solid up-pointing block arrow: a triangular head over a shaft
class _CueArrowPainter extends CustomPainter {
  _CueArrowPainter(this.blur);
  final double blur;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.68, h * 0.5)
      ..lineTo(w * 0.68, h)
      ..lineTo(w * 0.32, h)
      ..lineTo(w * 0.32, h * 0.5)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = blackColor.withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2));
    canvas.drawPath(path, Paint()..color = whiteColor);
  }

  @override
  bool shouldRepaint(covariant _CueArrowPainter oldDelegate) => oldDelegate.blur != blur;
}

/// Widget class that handles all upgrade-related UI components
/// Manages the visual presentation of upgrade options, pricing, and purchase flow
class UpgradeWidget {

  final BuildContext context;
  final String price;
  final int counter;

  UpgradeWidget(this.context, {
    required this.price,
    required this.counter,
  });

  static const TextScaler _fixedScale = TextScaler.linear(1.0);

  TextStyle premiumTextStyle(double fontSize, Color color, {bool isBold = true, bool hasShadow = false}) => TextStyle(
    fontSize: fontSize,
    fontWeight: (isBold) ? FontWeight.bold: FontWeight.normal,
    fontFamily: context.font(),
    color: color,
    decoration: TextDecoration.none,
    shadows: (hasShadow) ? [Shadow(
      color: blackColor.withValues(alpha: 0.8),
      blurRadius: context.premiumTitleShadowBlur(),
    )]: null,
  );

  /// Wraps a row so it scales down instead of overflowing on narrow screens
  Widget premiumRow(Widget child) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: context.premiumRowMaxWidth()),
    child: FittedBox(fit: BoxFit.scaleDown, child: child),
  );

  /// The benefits in one translucent plate, so the dimmed car signal behind shows through
  Widget premiumPlate(List<String> lines) => Container(
    width: context.premiumContentWidth(),
    alignment: Alignment.center,
    padding: EdgeInsets.symmetric(
      vertical: context.premiumPlatePaddingV(),
      horizontal: context.premiumPlatePaddingH(),
    ),
    decoration: BoxDecoration(
      color: premiumPlateColor,
      border: Border.all(color: grayColor, width: context.premiumPlateBorderWidth()),
      borderRadius: BorderRadius.circular(context.premiumPlateRadius()),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) SizedBox(height: context.premiumPlateLineGap()),
        FittedBox(fit: BoxFit.scaleDown,
          child: Text(lines[i],
            style: premiumTextStyle(context.premiumBenefitFontSize(), whiteColor, hasShadow: true),
            textScaler: _fixedScale,
          ),
        ),
      ],
    ]),
  );

  /// Title, then what premium gives, then its price: the order the buyer reads before pressing
  Widget premiumInfo({required void Function() onBuy}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      premiumRow(Text(context.premiumPlan(),
        style: premiumTextStyle(context.premiumTitleFontSize(), whiteColor, hasShadow: true),
        textScaler: _fixedScale,
      )),
      SizedBox(height: context.premiumInfoGap()),
      premiumPlate([context.carSignalAvailable(), context.removeAllAds()]),
      if (price.isNotEmpty) SizedBox(height: context.premiumInfoGap()),
      if (price.isNotEmpty) premiumRow(GestureDetector(
        onTap: onBuy,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.premiumPricePillPaddingH(),
            vertical: context.premiumPricePillPaddingV(),
          ),
          decoration: const ShapeDecoration(color: yellowColor, shape: StadiumBorder()),
          child: Text(price,
            style: premiumTextStyle(context.premiumPriceFontSize(), signalGrayColor),
            textScaler: _fixedScale,
          ),
        ),
      )),
    ],
  );

  /// Arrow plus "Buy", pointing at the push button from below (JP) or above (elsewhere).
  /// Only the text shrinks to stay clear of the right country-switch FAB.
  Widget premiumCue({
    required void Function() onBuy,
    required Animation<double> blink,
  }) {
    final arrow = SizedBox(
      width: context.premiumCueArrowWidth(),
      height: context.premiumCueArrowHeight(),
      child: CustomPaint(painter: _CueArrowPainter(context.premiumTitleShadowBlur())),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBuy,
      child: FadeTransition(
        opacity: cueOpacity(blink),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          (context.premiumCueBelow(counter)) ? arrow: RotatedBox(quarterTurns: 2, child: arrow),
          SizedBox(width: context.premiumCueArrowGap()),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.premiumCueTextMaxWidth()),
            child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(context.toPurchase(),
                style: premiumTextStyle(context.premiumCaptionFontSize(), whiteColor, hasShadow: true),
                textScaler: _fixedScale,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// Restore, a quiet underlined link in the bottom-left corner
  Widget premiumRestore({required void Function() onRestore}) => SizedBox(
    width: context.premiumRestoreMaxWidth(),
    height: context.premiumRestoreHeight(),
    child: TextButton(
      onPressed: onRestore,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(context.toRestore(),
            style: premiumTextStyle(context.premiumRestoreFontSize(), whiteColor, isBold: false).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: whiteColor,
            ),
            textScaler: _fixedScale,
          ),
        ),
      ),
    ),
  );

  /// White back button, the same "<" as the settings page this page is pushed from
  Widget premiumBack({required void Function() onBack}) => IconButton(
    icon: Icon(Icons.arrow_back_ios, color: whiteColor, size: context.appBarIconSize()),
    onPressed: onBack,
  );

  /// The back button placed where the settings AppBar puts its leading "<", for the page's Stack.
  /// No height is imposed, so the tap target never shrinks below 48×48 on a short bar,
  /// and the half-size shift keeps it centred on that point whatever size the button takes.
  Widget premiumBackLayer({required void Function() onBack}) => Positioned(
    left: context.premiumBackCenterX(),
    top: context.premiumBackCenterY(),
    child: FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: premiumBack(onBack: onBack),
    ),
  );

  /// Show loading indicator during purchase process
  Widget circularProgressIndicator() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: greenColor),
      SizedBox(height: context.upgradeCircularProgressMarginBottom()),
    ]
  );

  /// Purchase or restore result dialog (success or error with errorCode)
  Future<void> purchaseDialog({
    required bool isSuccess,
    required bool isRestore,
    PurchasesErrorCode? errorCode,
  }) => showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(isSuccess ? context.premiumPlan(): context.errorPurchaseTitle(isRestore)),
      content: Text(isSuccess ? context.successPurchaseMessage(isRestore): context.purchaseErrorMessage(errorCode, isRestore)),
      actions: [
        CupertinoDialogAction(
          onPressed: () => isSuccess ? context.pushHomePage():Navigator.pop(context),
          child: Text(context.confirmed(), style: TextStyle(color: Colors.blue))
        ),
      ],
    )
  );
}
