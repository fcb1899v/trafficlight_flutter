import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';
import 'sound_manager.dart';
import 'analytics.dart';
import 'upgrade.dart';

/// Main home page widget that displays the traffic signal simulation
/// Handles signal state management, user interactions, and audio/visual feedback
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read plan notifier for actions and watch premium status
    final plan = ref.read(planProvider.notifier);
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    // Watch time-related state providers (the user's saved settings)
    final savedWaitTime = ref.watch(waitTimeProvider);
    final savedGoTime = ref.watch(goTimeProvider);
    final savedFlashTime = ref.watch(flashTimeProvider);
    final savedYellowTime = ref.watch(yellowTimeProvider);
    final savedArrowTime = ref.watch(arrowTimeProvider);
    final isSound = ref.watch(isSoundProvider);
    // Local state for signal simulation
    final signalColor = useState([false, false, false]); //isGreen, isYellow, isArrow
    final counter = useState(0);
    // Which flag to show; separate from counter so AU/NZ/SG/CA can share a signal style
    final flagKey = useState("us");
    // The locale-detected flag and its style group, restored when paging returns to that group
    final detectedFlagKey = useRef("us");
    final detectedGroupKey = useRef("us");
    final isPressed = useState(false);
    final isFlash = useState(false);
    final opaque = useState(false);
    final isPedestrian = useState(true);
    final countDown = useState(0);
    final lifecycle = useAppLifecycleState();
    // Car-signal trial for unpurchased users: trialActive is true from the tap until the paywall or an abort
    final premiumPrice = useValueListenable(PremiumPrice.value);
    final trialCloseCount = useState("trialPaywallCloseCount".getSettingsValueInt(0));
    final trialActive = useState(false);
    // Stays true until the trial's cycle ends, even after an abort, so that cycle keeps its fixed times
    final useCycleDefaults = useState(false);
    final trialToggleCount = useRef(0);
    final trialPressType = useRef("none");
    final autoPressTimer = useRef<Timer?>(null);
    // True while the running cycle was pressed by the trial (manually or automatically), so only that cycle ends on the paywall
    final trialOwnsCycle = useRef(false);
    // The newest pushButtonActions, so a timer started in an older build still runs on the current times
    final pushLatest = useRef<Future<void> Function()?>(null);
    // Swings the padlock when it is tapped
    final padlockSwing = useAnimationController(duration: const Duration(milliseconds: 600));
    // True once the padlock has been tapped, so the next tap opens the purchase page
    final isLockTapped = useRef(false);
    // Blinks the trial banner, at the same cycle and curve as the purchase page's "Buy" cue, but without its 5-cycle stop
    final bannerBlink = useAnimationController(duration: cueBlinkCycle);
    final reduceMotion = premiumReduceMotion(context);
    useEffect(() {
      if (trialActive.value && !reduceMotion) {
        bannerBlink.repeat();
      } else {
        bannerBlink.stop();
        bannerBlink.value = 0;
      }
      return null;
    }, [trialActive.value, reduceMotion]);
    // The trial's cycle runs on the default times; any other cycle on the user's own settings
    final waitTime = useCycleDefaults.value ? initialWaitTime: savedWaitTime;
    final goTime = useCycleDefaults.value ? initialGoTime: savedGoTime;
    final flashTime = useCycleDefaults.value ? initialFlashTime: savedFlashTime;
    final yellowTime = useCycleDefaults.value ? initialYellowTime: savedYellowTime;
    final arrowTime = useCycleDefaults.value ? initialArrowTime: savedArrowTime;
    // Unpurchased users get the mode button only once the store price is known
    final hasFreeModeButton = !isPremiumProvider && premiumPrice.isNotEmpty;
    // It carries the "Try" ribbon until the trial's paywall has been closed often enough, then a padlock
    final canShowTrialButton = hasFreeModeButton && trialCloseCount.value < maxTrialPaywallCloseCount;
    // Initialize audio and TTS managers
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());
    // Create home widget instance
    final home = HomeWidget(context,
      counter: counter.value,
      flagKey: flagKey.value,
      signalColor: signalColor.value,
      isFlash: isFlash.value,
      opaque: opaque.value,
      isPressed: isPressed.value,
      waitTime: waitTime,
      goTime: goTime,
      flashTime: flashTime,
      yellowTime: yellowTime,
      arrowTime: arrowTime,
    );

    /// Initialize app state and load saved settings
    Future<void> initState() async {
      plan.setCurrentPlan(isPremium.value);
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}".debugPrint();
      final (detectedCounter, detectedFlag) = await getCountryCounter();
      counter.value = detectedCounter;
      flagKey.value = detectedFlag;
      detectedFlagKey.value = detectedFlag;
      detectedGroupKey.value = detectedCounter.defaultFlagKey();
      "waitTime: $waitTime, goTime: $goTime, flashTime: $flashTime, yellowTime: $yellowTime, arrowTime: $arrowTime, isSound: $isSound".debugPrint();
    }

    // Initialize settings and audio on first frame
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await Settings.init(cacheProvider: SharePreferenceCache(),);
          // Price prefetch plus its delay, not behind the country or TTS setup; it only needs
          // Settings, where it stores the price. Configure stays in main()
          if (context.mounted && !ref.read(planProvider).isPremium) unawaited(PremiumPrice.prefetch());
          await initState();
        } finally {
          // The splash stays until settings and the country flag are set; TTS setup is not visual
          FlutterNativeSplash.remove();
        }
        await ttsManager.initTts();
      });
      return () async {
        await audioManager.stopAll();
        await audioManager.playLoopSound(index: 0, asset: soundRed[counter.value], volume: musicVolume, isSound: isSound);
      };
    }, const []);

    // Handle app lifecycle changes (pause audio when app is inactive)
    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          audioManager.stopAll();
          ttsManager.stopTts();
        }
      }
      return null;
    }, [lifecycle]);

    // Cancels a pending auto-press if the page is disposed mid-wait
    useEffect(() => () => autoPressTimer.value?.cancel(), const []);

    // car_trial_entry_view: once per launch, the first time the "Try" ribbon shows (never for the padlock)
    useEffect(() {
      if (canShowTrialButton && !SignalAnalytics.trialEntryViewLogged) {
        SignalAnalytics.trialEntryViewLogged = true;
        SignalAnalytics.log('car_trial_entry_view');
      }
      return null;
    }, [canShowTrialButton]);

    // Going to the background (`paused`, not `inactive` from Control Centre) aborts the trial.
    // A running cycle still finishes, just without the banner or the paywall.
    useEffect(() {
      // The padlock needs two taps again
      if (lifecycle == AppLifecycleState.paused) isLockTapped.value = false;
      if (lifecycle == AppLifecycleState.paused && trialActive.value) {
        SignalAnalytics.log('car_trial_end_aborted',
          {'toggle_count': trialToggleCount.value, 'press_type': isPressed.value ? trialPressType.value: 'none'});
        autoPressTimer.value?.cancel();
        trialActive.value = false;
        isPedestrian.value = true;
        // With no cycle running, the next press must use the saved times again
        if (!isPressed.value && !isFlash.value) useCycleDefaults.value = false;
      }
      return null;
    }, [lifecycle]);

    /// Play green signal sound
    setGreenSound() async {
      await audioManager.stopAll();
      await audioManager.playLoopSound(index: 0, asset: soundGreen[counter.value], volume: musicVolume, isSound: isSound);
    }

    /// Play red signal sound
    setRedSound() async {
      await audioManager.stopAll();
      await audioManager.playLoopSound(index: 0, asset: soundRed[counter.value], volume: musicVolume, isSound: isSound);
    }

    /// Trigger button press effects (vibration and sound)
    pushButtonEffect() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(index: 1, asset: buttonSound, volume: buttonVolume, isSound: isSound);
      if (counter.value == 0 && !signalColor.value[0]) await ttsManager.speakText("wait", isSound);
    }

    /// Calculate and display countdown timer
    calcCountDown() async {
      countDown.value = goTime + flashTime;
      "countDown: ${countDown.value}".debugPrint();
      await setGreenSound();
      for (int i = 0; i < goTime; i++) {
        await Future.delayed(const Duration(seconds: 1)).then((_) async {
          countDown.value = countDown.value - 1;
          "countDown: ${countDown.value}".debugPrint();
        });
      }
    }

    /// Navigate between different country signal styles
    /// @param isNext Whether to go to next or previous country
    /// The detected flag returns within its own group; another group shows its generic flag.
    nextOrBackCounter(bool isNext) {
      "${(isNext) ? "next": "back"}Counter".debugPrint();
      counter.value = (counter.value + ((isNext) ? 1: -1)) % signalNumber;
      final newGroupKey = counter.value.defaultFlagKey();
      flagKey.value = (newGroupKey == detectedGroupKey.value) ? detectedFlagKey.value: newGroupKey;
      "counter: ${counter.value}".debugPrint();
    }

    /// Set button to pressed state
    setPressedButtonState() {
      isPressed.value = true;
      "isPressed: ${isPressed.value}".debugPrint();
    }

    /// Set signal to green state
    setGreenState() {
      signalColor.value = [true, false, false];
      "greenState: ${signalColor.value}".debugPrint();
    }

    /// Set signal to yellow state
    setYellowState() {
      signalColor.value = [false, true, false];
      "yellowState: ${signalColor.value}".debugPrint();
    }

    /// Set signal to arrow state
    setArrowState() {
      signalColor.value = [false, false, true];
      "arrowState: ${signalColor.value}".debugPrint();
    }

    /// Set signal to flashing green state
    /// @param i Flash iteration counter
    flashGreenState(int i) {
      if (i == 0) {
        isFlash.value = true;
        "isFlash: ${isFlash.value}".debugPrint();
      }
      opaque.value = !opaque.value;
      "opaque: ${opaque.value}".debugPrint();
      if (i % 2 == 1) {
        countDown.value = (countDown.value - deltaFlash / 1000 * 2).toInt();
        "countDown: ${countDown.value}".debugPrint();
      }
    }

    /// Presses the push button by itself once trialAutoPressDelay passes without a press
    void armAutoPress() {
      autoPressTimer.value?.cancel();
      autoPressTimer.value = Timer(trialAutoPressDelay, () {
        if (trialActive.value && !isPressed.value) {
          trialPressType.value = "auto";
          trialOwnsCycle.value = true;
          pushLatest.value?.call();
        }
      });
    }

    /// Set signal to red state and reset button.
    /// A trial cycle opens the paywall here and the red sound resumes once it closes; a cycle started before "Try" ends without it.
    setRedState() async {
      final endsTrial = trialActive.value && trialOwnsCycle.value;
      final trialWaits = trialActive.value && !endsTrial;
      signalColor.value = [false, false, false];
      isFlash.value = false;
      isPressed.value = false;
      trialOwnsCycle.value = false;
      useCycleDefaults.value = trialWaits;
      if (endsTrial) trialActive.value = false;
      if (trialWaits) armAutoPress();
      "redState: ${signalColor.value}, isFlash: ${isFlash.value}, isPressed: ${isPressed.value}".debugPrint();
      if (endsTrial) {
        await audioManager.stopAll();
        await SignalAnalytics.log('car_trial_end_paywall',
          {'toggle_count': trialToggleCount.value, 'press_type': trialPressType.value});
        isPedestrian.value = true;
        if (context.mounted) await context.pushUpgradePage(source: UpgradeSource.trial);
        if (!context.mounted) return;
        trialCloseCount.value = "trialPaywallCloseCount".getSettingsValueInt(0);
      }
      await setRedSound();
    }

    /// Main button press action sequence
    /// Handles the complete signal cycle from button press to red signal
    // A waitTime below yellowTime+arrowTime doesn't shorten the cycle: the negative delay just completes instantly, so yellow+arrow still run in full.
    Future<void> pushButtonActions() async {
      // Trigger button press effects
      await pushButtonEffect();
      // Only activate if signal is red and button is not pressed
      if (!signalColor.value[0] && !isFlash.value && !isPressed.value) {
        // Set button to pressed state
        setPressedButtonState();
        // Wait and set yellow signal
        await Future.delayed(Duration(seconds: (waitTime - yellowTime - arrowTime)))
            .then((_) async => setYellowState());
        // Wait and set arrow signal
        await Future.delayed(Duration(seconds: yellowTime))
            .then((_) async => setArrowState());
        // Wait and set green signal
        await Future.delayed(Duration(seconds: arrowTime)).then((_) async {
          setGreenState();
          // Calculate countdown
          await calcCountDown();
          // Flash green signal
          for (int i = 0; i < flashTime * 1000 ~/ deltaFlash + 1; i++) {
            await Future.delayed(const Duration(milliseconds: deltaFlash))
                .then((_) async => flashGreenState(i));
          }
        });
        // Return to red signal
        await Future.delayed(const Duration(seconds: 0))
            .then((_) async => setRedState());
      }
    }

    pushLatest.value = pushButtonActions;

    /// Starts the car-signal trial: switches to the car display and shows the "trying" banner.
    /// The push button presses itself after trialAutoPressDelay; tapped mid-cycle, that cycle runs on unchanged and the wait starts after it.
    void startCarTrial() {
      final cycleRunning = isPressed.value || isFlash.value;
      trialActive.value = true;
      useCycleDefaults.value = !cycleRunning;
      trialToggleCount.value = 0;
      trialPressType.value = "none";
      isPedestrian.value = false;
      SignalAnalytics.log('car_trial_start');
      if (!cycleRunning) armAutoPress();
    }

    /// The push button's own tap handler.
    /// While the trial waits for a press, a manual tap cancels the pending auto-press before anything awaits.
    /// So the two can never both fire for the same cycle.
    void onPushButtonTap() {
      if (trialActive.value && !isPressed.value) {
        autoPressTimer.value?.cancel();
        trialPressType.value = "manual";
        trialOwnsCycle.value = true;
      }
      pushButtonActions();
    }

    /// Toggle between pedestrian and traffic signal modes
    void changeIsPedestrian() {
      isPedestrian.value = !isPedestrian.value;
      if (trialActive.value) trialToggleCount.value = trialToggleCount.value + 1;
      "isPedestrian: {isPedestrian.value}".debugPrint();
    }

    /// Navigate to previous or next country signal style
    /// @param isForward Whether to go forward or backward
    void countryBack(bool isForward) {
      // Change to previous/next signal
      nextOrBackCounter(isForward);
      // Change audio based on current signal state
      (signalColor.value[0]) ? setGreenSound() : setRedSound();
    }

    /// Navigate to settings page
    Future<void> toSettings() async {
      await audioManager.stopAll();
      if (context.mounted) context.pushSettingsPage();
    }

    /// Swings the padlock on every tap; a tap after an earlier one, once its swing ends, opens the purchase page.
    /// Opening the page, or going to the background, sets isLockTapped back to false.
    Future<void> tapPadlock() async {
      final opens = isLockTapped.value;
      isLockTapped.value = true;
      if (!premiumReduceMotion(context)) await padlockSwing.forward(from: 0).orCancel.catchError((_) {});
      if (!opens || !context.mounted) return;
      isLockTapped.value = false;
      await audioManager.stopAll();
      if (context.mounted) await context.pushUpgradePage(source: UpgradeSource.lock);
      if (context.mounted) (signalColor.value[0]) ? setGreenSound(): setRedSound();
    }

    return Scaffold(
      // The gear stays visible but disabled while the trial runs
      appBar: home.homeAppBar(
        onPressed: () async => await toSettings(),
        enabled: !trialActive.value,
      ),
      body: Stack(alignment: Alignment.center,
        children: [
          home.backGroundImage(),
          home.darkBackground(),
          Column(children: [
            const Spacer(flex: 1),
            // Display appropriate signal image based on mode
            (isPedestrian.value) ?
              home.pedestrianSignalImage(countDown: countDown.value):
              home.trafficSignalImage(),
            const Spacer(flex: 1),
            Stack(alignment: Alignment.topCenter,
              children: [
                home.pushButtonFrame(),
                home.pushButton(onTap: () => onPushButtonTap()),
                home.jpFrameLabel()
              ]
            ),
            const Spacer(flex: 1),
            // Show ad banner only for non-premium users
            if (!isPremiumProvider) const AdBannerWidget(),
          ]),
          // "Trying the car signal" banner, in both modes, laid over the seam between the signal and the push button.
          // Last in the Stack so it is drawn on top; IgnorePointer lets taps reach the push button beneath it.
          if (trialActive.value) Positioned(
            top: context.trialBannerCenterY(),
            left: 0, right: 0,
            child: IgnorePointer(child: FractionalTranslation(
              translation: const Offset(0, -0.5),
              child: Center(child: FadeTransition(opacity: cueOpacity(bannerBlink), child: home.carTrialBanner())),
            )),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.floatingMarginBottom()),
        child: Column(children: [
          const Spacer(flex: modeTopFlex),
          // One black button for everyone; unpurchased users see the "Try" ribbon, then the padlock, while no trial runs
          if (isPremiumProvider || trialActive.value) home.changeIsPedestrianButton(
            isPedestrian: isPedestrian.value,
            onPressed: () => changeIsPedestrian(),
          )
          else if (canShowTrialButton) home.changeIsPedestrianButton(
            isPedestrian: isPedestrian.value,
            onPressed: () => startCarTrial(),
            isTag: true,
            semanticsLabel: context.carSignalTrialButtonLabel(),
          )
          else if (hasFreeModeButton) home.changeIsPedestrianButton(
            isPedestrian: isPedestrian.value,
            onPressed: () => tapPadlock(),
            isPadlock: true,
            padlockSwing: padlockSwing,
            semanticsLabel: context.carSignalAvailable(),
          ),
          const Spacer(flex: modeBottomFlex),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [false, true].map((isForward) => home.countryChangeButton(
              onPressed: () => countryBack(isForward),
              isForward: isForward,
            )).toList(),
          )
        ]),
      ),
    );
  }
}

/// Widget class that handles all home page UI components
/// Manages the visual presentation of signals, buttons, and interactive elements
class HomeWidget {

  final BuildContext context;
  final int counter;
  final String? flagKey;
  final List<bool> signalColor;
  final bool isFlash;
  final bool opaque;
  final bool isPressed;
  final int waitTime;
  final int goTime;
  final int flashTime;
  final int yellowTime;
  final int arrowTime;

  HomeWidget(this.context, {
    required this.counter,
    this.flagKey,
    required this.signalColor,
    required this.isFlash,
    required this.opaque,
    required this.isPressed,
    required this.waitTime,
    required this.goTime,
    required this.flashTime,
    required this.yellowTime,
    required this.arrowTime,
  });

  /// Create the app bar for the home page
  /// @param onPressed Callback function for settings button; null hides it entirely
  /// @param enabled false keeps the gear visible but disabled and dimmed while the car-signal trial runs; it has no effect when onPressed is null
  PreferredSize homeAppBar({
    required void Function()? onPressed,
    bool enabled = true,
  }) => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.appTitle(),
        style: TextStyle(
          fontFamily: context.font("beon"),
          fontSize: context.appBarFontSize(),
          fontWeight: FontWeight.bold,
          color: whiteColor,
          decoration: TextDecoration.none
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
      toolbarHeight: context.appBarHeight(),
      backgroundColor: signalGrayColor,
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        if (onPressed != null) Opacity(
          opacity: enabled ? 1: 0.4,
          child: IconButton(
            icon: Icon(Icons.settings,
              color: whiteColor,
              size: context.appBarIconSize()
            ),
            onPressed: enabled ? onPressed: null,
          ),
        ),
      ],
    )
  );

  /// Create background image with country flags
  Widget backGroundImage() => Column(children: [
    const Spacer(flex: 1),
    countryFlagImage(),
    const Spacer(flex: 1),
    countryFlagImage(),
    const Spacer(flex: 1),
    SizedBox(height: context.admobHeight())
  ]);

  /// Display country flag image based on the detected/selected flag key
  Widget countryFlagImage() => (counter == 4 || counter == 5) ? Container(
    width: context.flagSize(),
    height:  context.flagSize(),
    decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
  ): SizedBox(
    height: context.flagSize(),
    child: SvgPicture.asset(countryFlag[flagKey ?? counter.defaultFlagKey()]!),
  );

  /// Create dark background overlay
  Widget darkBackground() => Container(
      width: context.width(),
      height: context.height(),
      color: backGroundColor[counter]
  );

  /// Mode button between the pedestrian and car signals: the same light box and black signal art for every user.
  /// The art shows the signal a tap switches to.
  /// [isTag] hangs the yellow swallowtail "Try" ribbon diagonally across the top-right corner (unpurchased users).
  /// [isPadlock] lays the yellow star padlock, outlined in black, over the centre of the art; it is never disabled.
  Widget changeIsPedestrianButton({
    required bool isPedestrian,
    required void Function() onPressed,
    bool isTag = false,
    bool isPadlock = false,
    Animation<double>? padlockSwing,
    String? semanticsLabel,
  }) {
    final size = context.floatingButtonSize();
    final iconHeight = context.modeIconHeight();
    final frameAsset = isPedestrian.frameAsset();
    // Only the height is set: the width follows the tall SVG's own shape.
    Widget art = SvgPicture.asset(frameAsset, height: iconHeight);
    // Behind the padlock only, the art shows through it at 80% opacity, never fully hidden
    if (isPadlock) art = Opacity(opacity: 0.8, child: art);
    Widget? padlock;
    if (isPadlock) {
      final lockHeight = context.modePadlockHeight();
      // padlock_star.svg's own black outline keeps the yellow padlock apart from the art behind it
      padlock = SvgPicture.asset(padlockStar, key: const Key('trialPadlock'), height: lockHeight * padlockOutlineScale);
      if (padlockSwing != null) {
        padlock = AnimatedBuilder(
          animation: padlockSwing,
          builder: (_, child) => Transform.rotate(
            alignment: Alignment.topCenter,
            angle: sin(padlockSwing.value * pi * 6) * 0.3 * (1 - padlockSwing.value),
            child: child,
          ),
          child: padlock,
        );
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Semantics(
          label: semanticsLabel,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: FloatingActionButton(
                key: const Key('modeButton'),
                backgroundColor: lightGrayColor,
                heroTag: 'mode',
                shape: floatingButtonShape(side: BorderSide(color: blackColor, width: context.modeButtonBorderWidth())),
                onPressed: onPressed,
                child: (padlock == null) ? art: Stack(alignment: Alignment.center, children: [art, padlock]),
              )),
              // Drawn over the button and past its edges; taps fall through to the button beneath
              if (isTag) Positioned.fill(child: IgnorePointer(child: trialRibbon())),
            ]),
          ),
        ),
      ],
    );
  }

  /// Yellow swallowtail ribbon across the mode button's top-right corner, at 45 degrees, with the "Try" word in bold.
  /// Its size and place come from trialRibbonFontSize(), trialRibbonThickness() and trialRibbonCenter().
  Widget trialRibbon() {
    final size = context.floatingButtonSize();
    final font = context.trialRibbonFontSize();
    final thickness = context.trialRibbonThickness();
    final centre = context.trialRibbonCenter();
    final wordLength = font * 3.3;
    final mid = Offset(size - centre / sqrt2, centre / sqrt2);
    return Stack(key: const Key('trialRibbon'), clipBehavior: Clip.none, children: [
      Positioned.fill(child: CustomPaint(painter: _TrialRibbonPainter(
        centre: mid,
        length: wordLength + thickness * 0.6 + font * 0.3,
        thickness: thickness,
        edgeWidth: context.trialRibbonEdgeWidth(),
      ))),
      Positioned(
        left: mid.dx - wordLength * 0.6,
        top: mid.dy - font * 0.7,
        width: wordLength * 1.2,
        height: font * 1.4,
        child: Transform.rotate(angle: pi / 4, child: Center(child: Text(context.carSignalTrialTag(),
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: trialTagTextColor,
            // English reads better in "roboto" than in "beon"; ja/zh keep their usual font.
            fontFamily: context.font("roboto"),
            fontSize: font,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
          textScaler: const TextScaler.linear(1.0),
        ))),
      ),
    ]);
  }

  /// Shape of the three buttons: an iOS-app-icon-like continuous corner, sized by floatingButtonRadius()
  OutlinedBorder floatingButtonShape({BorderSide side = BorderSide.none}) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(context.floatingButtonRadius()),
    side: side,
  );

  /// "Trying the car signal" banner, shown in both modes while the trial runs
  Widget carTrialBanner() => Container(
    key: const Key('carTrialBanner'),
    padding: EdgeInsets.symmetric(horizontal: context.floatingIconSize(), vertical: context.trialBannerPaddingV()),
    decoration: BoxDecoration(
      color: blackColor.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(context.floatingIconSize()),
    ),
    child: Text(context.carSignalTrialBanner(),
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
        color: whiteColor,
        fontFamily: context.font("beon"),
        fontSize: context.trialBannerFontSize(),
        fontWeight: FontWeight.bold,
      ),
      textScaler: const TextScaler.linear(1.0),
    ),
  );

  /// Country navigation button; isForward picks the forward or backward arrow
  Widget countryChangeButton({
    required void Function() onPressed,
    required bool isForward
  }) => Container(
    margin: EdgeInsets.only(left: context.floatingButtonSize() / 2),
    width: context.floatingButtonSize(),
    height: context.floatingButtonSize(),
    child: FloatingActionButton(
      backgroundColor: lightGrayColor,
      heroTag: isForward ? 'forward': 'back',
      shape: floatingButtonShape(side: BorderSide(color: blackColor, width: context.modeButtonBorderWidth())),
      onPressed: onPressed,
      child: SizedBox(
        height: context.floatingImageSize(),
        // The PNG is a white shape on transparent; recolor it black to match the inverted button.
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(blackColor, BlendMode.srcIn),
          child: Image.asset(isForward ? forwardArrow: backArrow),
        ),
      )
    ),
  );

  /// Create push button frame with appropriate styling based on signal state
  Widget pushButtonFrame() => Container(
    height: context.frameHeight(),
    padding: EdgeInsets.only(
      top: context.frameTopPadding()[counter],
      bottom: context.frameBottomPadding()[counter]
    ),
    child: Image(image: AssetImage(
      (!signalColor[0] && isPressed) ? "wait".buttonFrame()[counter]:
      (!signalColor[0]) ? "red".buttonFrame()[counter]:
      (isFlash && opaque) ? "off".buttonFrame()[counter]:
      "green".buttonFrame()[counter]
    ))
  );

  /// Create push button with appropriate image based on state
  /// @param onTap Callback function when button is tapped
  Widget pushButton({
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: context.buttonHeight()[counter],
      margin: EdgeInsets.only(top: context.buttonTopMargin()[counter]),
      child: Image(image: AssetImage(
        ((!signalColor[0] && isPressed) ? "on": "off").pushButtonImage()[counter]
      ))
    )
  );

  /// Create Japanese frame label with appropriate messages
  Widget jpFrameLabel() => Column(children: [
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: context.labelTopMargin()[counter]),
      height: context.labelHeight()[counter],
      width: context.labelWidth()[counter],
      color: blackColor,
      child: Text(jpFrameMessage(true),
        style: TextStyle(
          color: (counter == 4) ? whiteColor: redColor,
          fontSize: context.labelFontSize()[counter],
          fontWeight: FontWeight.bold,
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
    ),
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: context.labelMiddleMargin()[counter]),
      height: context.labelHeight()[counter],
      width: context.labelWidth()[counter],
      color: blackColor,
      child: Text(jpFrameMessage(false),
        style: TextStyle(
          color: (counter == 4) ? whiteColor: redColor,
          fontSize: context.labelFontSize()[counter],
          fontWeight: FontWeight.bold,
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
    ),
  ]);

  /// Get appropriate Japanese frame message based on signal state
  /// @param isUpper Whether this is the upper or lower message
  String jpFrameMessage(bool isUpper) =>
    (!signalColor[0] && isPressed && isUpper) ? "おまちください":
    (!signalColor[0] && !isPressed && counter == 5 && !isUpper) ? "おしてください":
    (!signalColor[0] && !isPressed && counter == 4 && !isUpper) ? "ふれてください":
    "";

  /// Create pedestrian signal image with countdown display
  /// @param countDown Current countdown value
  Widget pedestrianSignalImage({
    required int countDown,
  }) => Container(
    height: context.signalHeight(),
    padding: EdgeInsets.all(context.pedestrianSignalPadding()[counter]),
    child: Stack(alignment: Alignment.center,
      children: [
        Image(image: AssetImage(
          (signalColor[0] && isFlash && opaque) ? "off".pedestrianSignal()[counter]:
          (signalColor[0] && isFlash) ? "flash".pedestrianSignal()[counter]:
          (signalColor[0]) ? "green".pedestrianSignal()[counter]:
          "red".pedestrianSignal()[counter]
        )),
        if (counter == 2) countDownNumber(countDown),
        if (counter == 4) jpNewCountDown(countDown),
      ],
    ),
  );

  /// Create countdown display for Japanese new pedestrian signal
  /// @param countDown Current countdown value
  Widget jpNewCountDown(int countDown) => Container(
    padding: EdgeInsets.only(right: context.countDownRightPadding()),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: context.countMeterTopSpace()),
        for(int i = 0; i < 8; i++) ... {
          Row(children: [
            const Spacer(),
            SizedBox(
              width: context.countMeterWidth(),
              height: context.countMeterHeight(),
              child: Image.asset(countDown.countMeterColor(goTime + flashTime)[i] ? jpCountDownOn: jpCountDownOff),
            ),
            SizedBox(width: context.countMeterCenterSpace()),
            SizedBox(
              width: context.countMeterWidth(),
              height: context.countMeterHeight(),
              child: Image.asset(countDown.countMeterColor(goTime + flashTime)[i] ? jpCountDownOn: jpCountDownOff),
            ),
            const Spacer(),
          ]),
          SizedBox(height: context.countMeterSpace()),
        },
      ]
    )
  );

  /// Create countdown number display
  /// @param countDown Current countdown value
  Widget countDownNumber(int countDown) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      SizedBox(height: context.cdNumTopSpace()[counter]),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: context.cdNumLeftSpace()[counter]),
          // Countdown number for the 10 place
          Stack(children: [
            // Background Number
            countDownText("8", signalGrayColor),
            // Count Down Number
            Container(
              padding: EdgeInsets.only(left: context.cdTenLeftPadding(countDown, isFlash)[counter]),
              child: countDownText(countDown.cdTenNumberString(isFlash), countDown.cdTenColor(cdNumColor[counter], isFlash)),
            ),
          ]),
          // Countdown number for the first place
          Stack(children: [
            // Background Number
            countDownText("8", signalGrayColor),
            // Count Down Number
            Container(
              padding: EdgeInsets.only(left: context.cdFirstLeftPadding(countDown, isFlash)[counter]),
              child: countDownText(countDown.cdFirstNumberString(isFlash), countDown.cdFirstColor(cdNumColor[counter], isFlash)),
            ),
          ]),
        ],
      ),
    ],
  );

  /// Countdown text with the given color
  Text countDownText(String text, Color color) => Text(text,
    style: TextStyle(
      color: color,
      fontFamily: cdNumFont[counter],
      fontSize: context.cdNumFontSize()[counter],
      fontWeight: FontWeight.bold
    )
  );

  /// Create traffic signal image with appropriate styling
  Widget trafficSignalImage() => SizedBox(
    height: context.signalHeight(),
    child: Container(
      padding: EdgeInsets.all(context.trafficSignalPadding()[counter]),
      child: Stack(alignment: Alignment.center,
        children: [
          if (counter == 1) usOldSignalImage(true),
          if (counter == 1) usOldSignalImage(false),
          Image(image: AssetImage(
            (signalColor[1]) ? "yellow".trafficSignal()[counter]:
            (signalColor[2]) ? "arrow".trafficSignal()[counter]:
            (!signalColor[0]) ? "green".trafficSignal()[counter]:
            "red".trafficSignal()[counter]
          )),
        ],
      ),
    ),
  );

  /// Create US old traffic signal with animated flags
  /// @param isGo Whether this is the go flag or stop flag
  Widget usOldSignalImage(bool isGo) => AnimatedContainer(
    height: context.usOldSignalFlagHeight(),
    transform: Matrix4.rotationZ(((signalColor[0] && !isGo) || (!signalColor[0] && isGo)) ? 1.57: 0),
    duration: const Duration(seconds: flagRotationTime),
    child: Image(image: AssetImage(isGo ? usGoFlag: usStopFlag)),
  );
}

/// The "Try" ribbon's band: a 45-degree strip with a V notch cut into both ends, filled yellow with a dark edge
class _TrialRibbonPainter extends CustomPainter {
  _TrialRibbonPainter({required this.centre, required this.length, required this.thickness, required this.edgeWidth});

  final Offset centre;
  final double length, thickness, edgeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const along = Offset(1 / sqrt2, 1 / sqrt2);   // down the band, from its top-left end to its bottom-right end
    const across = Offset(1 / sqrt2, -1 / sqrt2); // across the band, toward the corner
    final start = centre - along * (length / 2), end = centre + along * (length / 2);
    final side = across * (thickness / 2), notch = along * (thickness * 0.3);
    final band = Path()..addPolygon([start + side, end + side, end - notch, end - side, start - side, start + notch], true);
    canvas.drawPath(band, Paint()..color = trialTagColor);
    canvas.drawPath(band, Paint()
      ..color = trialTagEdgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = edgeWidth
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_TrialRibbonPainter old) =>
    old.centre != centre || old.length != length || old.thickness != thickness || old.edgeWidth != edgeWidth;
}

