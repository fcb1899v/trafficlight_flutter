import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'plan_provider.dart';
import 'admob_banner.dart';
import 'sound_manager.dart';

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
    // Watch time-related state providers
    final waitTime = ref.watch(waitTimeProvider);
    final goTime = ref.watch(goTimeProvider);
    final flashTime = ref.watch(flashTimeProvider);
    final yellowTime = ref.watch(yellowTimeProvider);
    final arrowTime = ref.watch(arrowTimeProvider);
    final isSound = ref.watch(isSoundProvider);
    // Local state for signal simulation
    final signalColor = useState([false, false, false]); //isGreen, isYellow, isArrow
    final counter = useState(0);
    final isPressed = useState(false);
    final isFlash = useState(false);
    final opaque = useState(false);
    final isPedestrian = useState(true);
    final countDown = useState(0);
    final lifecycle = useAppLifecycleState();
    // Initialize audio and TTS managers
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());
    // Create home widget instance
    final home = HomeWidget(context,
      counter: counter.value,
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
      counter.value = await getCountryCounter();
      "waitTime: $waitTime, goTime: $goTime, flashTime: $flashTime, yellowTime: $yellowTime, arrowTime: $arrowTime, isSound: $isSound".debugPrint();
    }

    // Initialize settings and audio on first frame
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        await initState();
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
    nextOrBackCounter(bool isNext) {
      "${(isNext) ? "next": "back"}Counter".debugPrint();
      counter.value = (counter.value + ((isNext) ? 1: -1)) % signalNumber;
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

    /// Set signal to red state and reset button
    setRedState() async {
      signalColor.value = [false, false, false];
      isFlash.value = false;
      isPressed.value = false;
      "redState: ${signalColor.value}, isFlash: ${isFlash.value}, isPressed: ${isPressed.value}".debugPrint();
      await setRedSound();
    }

    /// Main button press action sequence
    /// Handles the complete signal cycle from button press to red signal
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

    /// Toggle between pedestrian and traffic signal modes
    void changeIsPedestrian() {
      isPedestrian.value = !isPedestrian.value;
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

    return Scaffold(
      appBar: home.homeAppBar(onPressed: () async => await toSettings()),
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
                home.pushButton(onTap: () => pushButtonActions()),
                home.jpFrameLabel()
              ]
            ),
            const Spacer(flex: 1),
            // Show ad banner only for non-premium users
            if (!isPremiumProvider) const AdBannerWidget(),
          ]),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.floatingMarginBottom()),
        child: Column(children: [
          const Spacer(flex: 3),
          // Show mode toggle button only for premium users
          if (isPremiumProvider) home.changeIsPedestrianButton(
            onPressed: () => changeIsPedestrian()
          ),
          const Spacer(flex: 2),
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
  /// @param onPressed Callback function for settings button
  PreferredSize homeAppBar({
    required void Function() onPressed
  }) => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.appTitle(),
        style: TextStyle(
          fontFamily: context.font(),
          fontSize: context.appBarFontSize(),
          fontWeight: FontWeight.bold,
          color: whiteColor,
          decoration: TextDecoration.none
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
      backgroundColor: signalGrayColor,
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(Icons.settings,
            color: whiteColor,
            size: context.appBarIconSize()
          ),
          onPressed: onPressed,
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

  /// Display country flag image based on current counter
  Widget countryFlagImage() => (counter == 4 || counter == 5) ? Container(
    width: context.flagSize(),
    height:  context.flagSize(),
    decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
  ): SizedBox(
    height: context.flagSize(),
    child: Image.asset(countryFlag[counter]),
  );

  /// Create dark background overlay
  Widget darkBackground() => Container(
      width: context.width(),
      height: context.height(),
      color: backGroundColor[counter]
  );

  /// Create mode toggle button (pedestrian/traffic signal)
  /// @param onPressed Callback function when button is pressed
  Widget changeIsPedestrianButton({
    required void Function() onPressed
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        width: context.floatingButtonSize(),
        height: context.floatingButtonSize(),
        child: FloatingActionButton(
          backgroundColor: blackColor,
          heroTag:'mode',
          onPressed: onPressed,
          child: Icon(Icons.cached,
            color: whiteColor,
            size: context.floatingIconSize()
          ),
        )
      )
    ]
  );

  /// Create country navigation button
  /// @param onPressed Callback function when button is pressed
  /// @param isForward Whether this is forward or backward button
  Widget countryChangeButton({
    required void Function() onPressed,
    required bool isForward
  }) => Container(
    margin: EdgeInsets.only(left: context.floatingButtonSize() / 2),
    width: context.floatingButtonSize(),
    height: context.floatingButtonSize(),
    child: FloatingActionButton(
      foregroundColor: whiteColor,
      backgroundColor: blackColor,
      heroTag: isForward ? 'forward': 'back',
      onPressed: onPressed,
      child: SizedBox(
        height: context.floatingImageSize(),
        child: Image.asset(isForward ? forwardArrow: backArrow),
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

  /// Create countdown text with appropriate styling
  /// @param text Text to display
  /// @param color Text color
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

/// Get default country counter based on device locale
/// @return Country counter index for signal style
Future<int> getCountryCounter() async {
  final locale = await Devicelocale.currentLocale ?? "en-US";
  final countryCode = locale.substring(3, 5);
  final counter = countryCode.getDefaultCounter();
  "Locale: $locale, counter: $counter".debugPrint();
  return counter;
}

