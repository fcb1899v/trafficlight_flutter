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

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final plan = ref.read(planProvider.notifier);
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));

    final waitTime = ref.watch(waitTimeProvider);
    final goTime = ref.watch(goTimeProvider);
    final flashTime = ref.watch(flashTimeProvider);
    final yellowTime = ref.watch(yellowTimeProvider);
    final arrowTime = ref.watch(arrowTimeProvider);
    final isSound = ref.watch(isSoundProvider);

    final signalColor = useState([false, false, false]); //isGreen, isYellow, isArrow
    final counter = useState(0);
    final isPressed = useState(false);
    final isFlash = useState(false);
    final opaque = useState(false);
    final isPedestrian = useState(true);
    final countDown = useState(0);
    final lifecycle = useAppLifecycleState();

    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());

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

    Future<void> initState() async {
      plan.setCurrentPlan(isPremium.value);
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}".debugPrint();
      counter.value = await getCountryCounter();
      "waitTime: $waitTime, goTime: $goTime, flashTime: $flashTime, yellowTime: $yellowTime, arrowTime: $arrowTime, isSound: $isSound".debugPrint();
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Settings.init(cacheProvider: SharePreferenceCache(),);
        await initState();
        await ttsManager.initTts();
      });
      return () async {
        await audioManager.playLoopSound(index: 0, asset: soundRed[counter.value], volume: musicVolume, isSound: isSound);
      };
    }, const []);

    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          audioManager.stopAll();
          ttsManager.stopTts();
        }
      }
      return null;
    }, [lifecycle]);

    setGreenSound() async {
      await audioManager.stopAll();
      await audioManager.playLoopSound(index: 0, asset: soundGreen[counter.value], volume: musicVolume, isSound: isSound);
    }

    setRedSound() async {
      await audioManager.stopAll();
      await audioManager.playLoopSound(index: 0, asset: soundRed[counter.value], volume: musicVolume, isSound: isSound);
    }

    pushButtonEffect() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(index: 1, asset: buttonSound, volume: buttonVolume, isSound: isSound);
      if (counter.value == 0 && !signalColor.value[0]) await ttsManager.speakText("wait", isSound);
    }

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

    nextOrBackCounter(bool isNext) {
      "${(isNext) ? "next": "back"}Counter".debugPrint();
      counter.value = (counter.value + ((isNext) ? 1: -1)) % signalNumber;
      "counter: ${counter.value}".debugPrint();
    }

    //ボタンが押された状態にする
    setPressedButtonState() {
      isPressed.value = true;
      "isPressed: ${isPressed.value}".debugPrint();
    }

    //緑色点灯状態にする
    setGreenState() {
      signalColor.value = [true, false, false];
      "greenState: ${signalColor.value}".debugPrint();
    }

    //黄色点灯状態にする
    setYellowState() {
      signalColor.value = [false, true, false];
      "yellowState: ${signalColor.value}".debugPrint();
    }

    //矢印点灯状態にする
    setArrowState() {
      signalColor.value = [false, false, true];
      "arrowState: ${signalColor.value}".debugPrint();
    }

    //緑色点滅状態にする
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

    //赤色点灯状態になる
    setRedState() async {
      signalColor.value = [false, false, false];
      isFlash.value = false;
      isPressed.value = false;
      "redState: ${signalColor.value}, isFlash: ${isFlash.value}, isPressed: ${isPressed.value}".debugPrint();
      await setRedSound();
    }

    Future<void> pushButtonActions() async {
      //ボタンを押した時の効果
      await pushButtonEffect();
      //赤色点灯かつボタンが押されていないときに発動
      if (!signalColor.value[0] && !isFlash.value && !isPressed.value) {
        //ボタンが押された状態にする
        setPressedButtonState();
        //黄色点灯状態にする
        await Future.delayed(Duration(seconds: (waitTime - yellowTime - arrowTime)))
            .then((_) async => setYellowState());
        //矢印点灯状態にする
        await Future.delayed(Duration(seconds: yellowTime))
            .then((_) async => setArrowState());
        //緑色点灯状態にする
        await Future.delayed(Duration(seconds: arrowTime)).then((_) async {
          setGreenState();
          //countDownの計算
          await calcCountDown();
          //緑色点滅状態にする
          for (int i = 0; i < flashTime * 1000 ~/ deltaFlash + 1; i++) {
            await Future.delayed(const Duration(milliseconds: deltaFlash))
                .then((_) async => flashGreenState(i));
          }
        });
        //赤色点灯状態になる
        await Future.delayed(const Duration(seconds: 0))
            .then((_) async => setRedState());
      }
    }

    void changeIsPedestrian() {
      isPedestrian.value = !isPedestrian.value;
      "isPedestrian: {isPedestrian.value}".debugPrint();
    }

    void countryBack(bool isForward) {
      //前の信号に変更
      nextOrBackCounter(isForward);
      //音声を変更
      (signalColor.value[0]) ? setGreenSound() : setRedSound();
    }

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
            if (!isPremiumProvider) const AdBannerWidget(),
          ]),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.floatingMarginBottom()),
        child: Column(children: [
          const Spacer(flex: 3),
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

  PreferredSize homeAppBar({
    required void Function() onPressed
  }) => PreferredSize(
    preferredSize: Size.fromHeight(context.appBarHeight()),
    child: AppBar(
      title: Text(context.appTitle(),
        style: TextStyle(
          fontFamily: context.titleFont(),
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


  Widget backGroundImage() => Column(children: [
    const Spacer(flex: 1),
    countryFlagImage(),
    const Spacer(flex: 1),
    countryFlagImage(),
    const Spacer(flex: 1),
    SizedBox(height: context.admobHeight())
  ]);

  Widget countryFlagImage() => (counter == 4 || counter == 5) ? Container(
    width: context.flagSize(),
    height:  context.flagSize(),
    decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
  ): SizedBox(
    height: context.flagSize(),
    child: Image.asset(countryFlag[counter]),
  );

  Widget darkBackground() => Container(
      width: context.width(),
      height: context.height(),
      color: backGroundColor[counter]
  );

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

  // Push Button Frame
  Widget pushButtonFrame() => Container(
    height: context.frameHeight(),
    padding: EdgeInsets.only(
      top: context.height() * frameTopPaddingRate[counter],
      bottom: context.height() * frameBottomPaddingRate[counter]
    ),
    child: Image(image: AssetImage(
      (!signalColor[0] && isPressed) ? buttonFrameWaitString[counter]:
      (!signalColor[0]) ? buttonFrameRedString[counter]:
      (isFlash && opaque) ? buttonFrameOffString[counter]:
      buttonFrameGreenString[counter]
    ))
  );

  //Push Button Image
  Widget pushButton({
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: context.height() * buttonHeightRate[counter],
      margin: EdgeInsets.only(top: context.height() * buttonTopMarginRate[counter]),
      child: Image(image: AssetImage(
        (!signalColor[0] && isPressed) ? pushButtonOnString[counter]:
        pushButtonOffString[counter]
      ))
    )
  );

  // Push Button Japanese Frame label
  Widget jpFrameLabel() => Column(children: [
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: context.height() * labelTopMarginRate[counter]),
      height: context.height() * labelHeightRate[counter],
      width: context.height() * labelWidthRate[counter],
      color: blackColor,
      child: Text(jpFrameMessage(true),
        style: TextStyle(
          color: (counter == 4) ? whiteColor: redColor,
          fontSize: context.height() * labelFontSizeRate[counter],
          fontWeight: FontWeight.bold,
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
    ),
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: context.height() * labelMiddleMarginRate[counter]),
      height: context.height() * labelHeightRate[counter],
      width: context.height() * labelWidthRate[counter],
      color: blackColor,
      child: Text(jpFrameMessage(false),
        style: TextStyle(
          color: (counter == 4) ? whiteColor: redColor,
          fontSize: context.height() * labelFontSizeRate[counter],
          fontWeight: FontWeight.bold,
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
    ),
  ]);

  String jpFrameMessage(bool isUpper) =>
    (!signalColor[0] && isPressed && isUpper) ? "おまちください":
    (!signalColor[0] && !isPressed && counter == 5 && !isUpper) ? "おしてください":
    (!signalColor[0] && !isPressed && counter == 4 && !isUpper) ? "ふれてください":
    "";

  /// Pedestrian Signal Image
  Widget pedestrianSignalImage({
    required int countDown,
  }) => Container(
    height: context.signalHeight(),
    padding: EdgeInsets.all(context.height() * pedestrianSignalPaddingRate[counter]),
    child: Stack(alignment: Alignment.center,
      children: [
        Image(image: AssetImage(
          (signalColor[0] && isFlash && opaque) ? pedestrianSignalOffString[counter]:
          (signalColor[0] && isFlash) ? pedestrianSignalFlashString[counter]:
          (signalColor[0]) ? pedestrianSignalGreenString[counter]:
          pedestrianSignalRedString[counter]
        )),
        if (counter == 2) countDownNumber(countDown),
        if (counter == 4) jpNewCountDown(countDown),
      ],
    ),
  );

  // Countdown for Jp New Pedestrian Signal
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

  //Countdown Number
  Widget countDownNumber(int countDown) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      SizedBox(height: context.height() * cdNumTopSpaceRate[counter]),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: context.height() * cdNumLeftSpaceRate[counter]),
          //Countdown number for the 10 place
          Stack(children: [
            //Background Number
            countDownText("8", signalGrayColor),
            //Count Down Number
            Container(
              padding: EdgeInsets.only(left: context.height() * countDown.cdTenLeftPaddingRate(counter, isFlash)),
              child: countDownText(countDown.cdTenNumberString(isFlash), countDown.cdTenColor(cdNumColor[counter], isFlash)),
            ),
          ]),
          //Countdown number for the first place
          Stack(children: [
            //Background Number
            countDownText("8", signalGrayColor),
            //Count Down Number
            Container(
              padding: EdgeInsets.only(left: context.height() * countDown.cdFirstLeftPaddingRate(counter, isFlash)),
              child: countDownText(countDown.cdFirstNumberString(isFlash), countDown.cdFirstColor(cdNumColor[counter], isFlash)),
            ),
          ]),
        ],
      ),
    ],
  );

  //Countdown Text
  Text countDownText(String text, Color color) => Text(text,
    style: TextStyle(
      color: color,
      fontFamily: cdNumFont[counter],
      fontSize: context.height() * cdNumFontSizeRate[counter],
      fontWeight: FontWeight.bold
    )
  );

  /// Traffic Signal Image
  Widget trafficSignalImage() => SizedBox(
    height: context.signalHeight(),
    child: Container(
      padding: EdgeInsets.all(context.height() * trafficSignalPaddingRate[counter]),
      child: Stack(alignment: Alignment.center,
        children: [
          if (counter == 1) usOldSignalImage(true),
          if (counter == 1) usOldSignalImage(false),
          Image(image: AssetImage(
            (signalColor[1]) ? trafficSignalYellowString[counter]:
            (signalColor[2]) ? trafficSignalArrowString[counter]:
            (!signalColor[0]) ? trafficSignalGreenString[counter]:
            trafficSignalRedString[counter]
          )),
        ],
      ),
    ),
  );

  // US Old Traffic Signal
  Widget usOldSignalImage(bool isGo) => AnimatedContainer(
    height: context.usOldSignalFlagHeight(),
    transform: Matrix4.rotationZ(((signalColor[0] && !isGo) || (!signalColor[0] && isGo)) ? 1.57: 0),
    duration: const Duration(seconds: flagRotationTime),
    child: Image(image: AssetImage(isGo ? usGoFlag: usStopFlag)),
  );
}

Future<int> getCountryCounter() async {
  final locale = await Devicelocale.currentLocale ?? "en-US";
  final countryCode = locale.substring(3, 5);
  final counter = countryCode.getDefaultCounter();
  "Locale: $locale, counter: $counter".debugPrint();
  return counter;
}

