import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';
import 'viewmodel.dart';
import 'admob_banner.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();

    final counter = useState(0);
    final isPressed = useState(false);
    final isGreen = useState(false);
    final isYellow = useState(false);
    final isArrow = useState(false);
    final isFlash = useState(false);
    final opaque = useState(false);
    final isPedestrian = useState(true);
    final isSound = useState('sound'.getSettingsValueBool(true));

    final plan = ref.read(planProvider.notifier);
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));

    final countDown = useState(0);
    final waitTime = useState("wait".getSettingsValueInt(waitTime_0));
    final goTime = useState("go".getSettingsValueInt(goTime_0));
    final flashTime = useState("flash".getSettingsValueInt(flashTime_0));
    final yellowTime = useState(yellowTime_0);
    final arrowTime = useState(arrowTime_0);

    final audioPlayer = useState(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    final buttonPlayer = useState(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    final audioSound = useState(soundRed[counter.value]);
    final flutterTts = useState(FlutterTts());

    initSounds() async {
      final locale = await Devicelocale.currentLocale ?? "en-US";
      final countryCode = locale.substring(3, 5);
      counter.value = countryCode.getDefaultCounter();
      await flutterTts.value.setLanguage(locale);
      await flutterTts.value.setVolume(isSound.value ? musicVolume: 0);
      await buttonPlayer.value.setVolume(isSound.value ? buttonVolume: 0);
      await buttonPlayer.value.setSourceAsset(buttonSound);
      await audioPlayer.value.setVolume(isSound.value ? musicVolume: 0);
      await audioPlayer.value.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.value.setSourceAsset(audioSound.value);
      await audioPlayer.value.release();
      "Locale: $locale, counter: ${counter.value}".debugPrint();
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Platform.isIOS || Platform.isMacOS) initPlugin(context);
        initSounds();
        initSettings();
        plan.setCurrentPlan(isPremium.value);
        "width: $width, height: $height".debugPrint();
        "waitTIme: ${waitTime.value}, goTime: ${goTime.value}, flashTime: ${flashTime.value}".debugPrint();
        "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}".debugPrint();
        "redSound: play: ${audioSound.value}".debugPrint();
      });
      return () async => (isSound.value) ? null: await audioPlayer.value.stop();
    }, const []);

    setGreenSound() async {
      await audioPlayer.value.stop();
      "redSound: stop".debugPrint();
      audioSound.value = soundGreen[counter.value];
      await audioPlayer.value.setSourceAsset(audioSound.value);
      if (isSound.value) await audioPlayer.value.resume();
      "greenSound: play: ${soundGreen[counter.value]}".debugPrint();
    }

    setRedSound() async {
      await audioPlayer.value.stop();
      "greenSound: stop".debugPrint();
      audioSound.value = soundRed[counter.value];
      await audioPlayer.value.setSourceAsset(audioSound.value);
      if (isSound.value) await audioPlayer.value.resume();
      "redSound: play: ${soundRed[counter.value]}".debugPrint();
    }

    setTimeParameter() async {
      waitTime.value = "wait".getSettingsValueInt(waitTime_0);
      goTime.value = "go".getSettingsValueInt(goTime_0);
      flashTime.value = "flash".getSettingsValueInt(flashTime_0);
      "waitTime: ${waitTime.value}, goTime: ${goTime.value}, flashTime: ${flashTime.value}".debugPrint();
      yellowTime.value = (waitTime.value > yellowTime_0 + arrowTime_0) ? yellowTime_0: 2;
      arrowTime.value = (waitTime.value > yellowTime_0 + arrowTime_0) ? yellowTime_0: 2;
      "yellowTime: ${yellowTime.value}, arrowTime: ${arrowTime.value}".debugPrint();
    }

    setAudioVolume() async {
      await flutterTts.value.setVolume(isSound.value ? musicVolume: 0);
      await buttonPlayer.value.setVolume(isSound.value ? buttonVolume: 0);
      await audioPlayer.value.setVolume(isSound.value ? musicVolume: 0);
    }

    pushButtonEffect() async {
      if (counter.value == 0 && !isGreen.value) await flutterTts.value.speak("wait");
      await buttonPlayer.value.resume();
      "button: $buttonSound".debugPrint();
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    }

    calcCountDown() async {
      countDown.value = goTime.value + flashTime.value;
      "countDown: ${countDown.value}".debugPrint();
      if (isSound.value) await setGreenSound();
      for (int i = 0; i < goTime.value; i++) {
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
      "isPressedState: isPressed: ${isPressed.value}".debugPrint();
    }

    //黄色点灯状態にする
    setYellowState() {
      isYellow.value = true;
      isArrow.value = false;
      isGreen.value = false;
      "yellowState: isYellow: ${isYellow.value}".debugPrint();
    }

    //矢印点灯状態にする
    setArrowState() {
      isYellow.value = false;
      isArrow.value = true;
      isGreen.value = false;
      "arrowState: isArrow: ${isArrow.value}".debugPrint();
    }

    //緑色点灯状態にする
    setGreenState() {
      isYellow.value = false;
      isArrow.value = false;
      isGreen.value = true;
      "greenState: isGreen: ${isGreen.value}".debugPrint();
    }

    //緑色点滅状態にする
    flashGreenState(int i) {
      if (i == 0) {
        isFlash.value = true;
        "flashState: isGreen: ${isGreen.value}, isFlash: ${isFlash.value}".debugPrint();
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
      isGreen.value = false;
      isFlash.value = false;
      isPressed.value = false;
      "redState: isGreen: ${isGreen.value}, isFlash: ${isFlash.value}, isPressed: ${isPressed.value}".debugPrint();
      if (isSound.value) await setRedSound();
      await setAudioVolume();
    }

    return Scaffold(
      appBar: AppBar(
        title: titleText(context, context.appTitle()),
        backgroundColor: signalGrayColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: whiteColor, size: 32),
            onPressed: () async => {
              await audioPlayer.value.stop(),
              await buttonPlayer.value.stop(),
              context.pushSettingsPage(),
            }
          ),
        ],
      ),
      body: Stack(alignment: Alignment.center,
        children: [
          backGroundImage(context, height, counter.value),
          Container(width: width, height: height, color: backGroundColor[counter.value]),
          Column(
            children: [
            const Spacer(flex: 1),
            (isPedestrian.value) ?
              pedestrianSignalImage(context, counter.value, countDown.value, goTime.value + flashTime.value, isGreen.value, isFlash.value, opaque.value):
              trafficSignalImage(context, counter.value, goTime.value + flashTime.value, isGreen.value, isYellow.value, isArrow.value, opaque.value),
            const Spacer(flex: 1),
            Stack(alignment: Alignment.topCenter,
              children: [
                //Push Button Frame
                pushButtonFrame(context, counter.value, isGreen.value, isFlash.value, opaque.value, isPressed.value)      ,
                //Push Button
                GestureDetector(
                  child: pushButtonImage(context, counter.value, isGreen.value, isPressed.value),
                  onTap: () async {
                    //ボタンを押した時の効果
                    await pushButtonEffect();
                    //赤色点灯かつボタンが押されていないときに発動
                    if (!isGreen.value && !isFlash.value && !isPressed.value) {
                      //各種パラメータの取得
                      await setTimeParameter();
                      await setAudioVolume();
                      //ボタンが押された状態にする
                      setPressedButtonState();
                      //黄色点灯状態にする
                      await Future.delayed(Duration(seconds: (waitTime.value - yellowTime.value - arrowTime.value)))
                          .then((_) async => setYellowState());
                      //矢印点灯状態にする
                      await Future.delayed(Duration(seconds: yellowTime.value))
                          .then((_) async => setArrowState());
                      //緑色点灯状態にする
                      await Future.delayed(Duration(seconds: arrowTime.value)).then((_) async {
                        setGreenState();
                        //countDownの計算
                        await calcCountDown();
                        //緑色点滅状態にする
                        for (int i = 0; i < flashTime.value * 1000 ~/ deltaFlash + 1; i++) {
                          await Future.delayed(const Duration(milliseconds: deltaFlash))
                              .then((_) async => flashGreenState(i));
                        }
                      });
                      //赤色点灯状態になる
                      await Future.delayed(const Duration(seconds: 0))
                          .then((_) async => setRedState());
                    }
                  },
                ),
                //Push Button Frame Label
                jpFrameLabel(context, counter.value, isPressed.value, isGreen.value)
              ]
            ),
            const Spacer(flex: 1),
            (isPremiumProvider) ? SizedBox(height: context.admobHeight()): const AdBannerWidget(),
          ]),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.admobHeight() + height * floatingButtonSizeRate / 2),
        child: Column(children: [
          const Spacer(flex: 3),
          if (isPremiumProvider) Row(children: [
            const Spacer(),
            SizedBox(
              width: height * floatingButtonSizeRate,
              height: height * floatingButtonSizeRate,
              child: FloatingActionButton(
                backgroundColor: blackColor,
                heroTag:'mode',
                child: Icon(Icons.cached, color: whiteColor, size: height * floatingIconSizeRate),
                onPressed: () async {
                  isPedestrian.value = !isPedestrian.value;
                  "changeMode".debugPrint();
                }
              )
            ),
          ]),
          const Spacer(flex: 2),
          Row(children: [
            Container(
              margin: const EdgeInsets.only(left: 32),
              width: height * floatingButtonSizeRate,
              height: height * floatingButtonSizeRate,
              child: FloatingActionButton(
                foregroundColor: whiteColor,
                backgroundColor: blackColor,
                heroTag:'back',
                child: SizedBox(
                  height: height * floatingImageSizeRate,
                  child: Image.asset(backArrow),
                ),
                //前の信号ボタンを押した時の処理
                onPressed: () async {
                  //前の信号に変更
                  nextOrBackCounter(false);
                  //音声を変更
                  if (isSound.value) {
                    (isGreen.value) ? setGreenSound() : setRedSound();
                    setAudioVolume();
                  }
                }
              ),
            ),
            const Spacer(),
            SizedBox(
              width: height * floatingButtonSizeRate,
              height: height * floatingButtonSizeRate,
              child: FloatingActionButton(
                foregroundColor: whiteColor,
                backgroundColor: blackColor,
                heroTag:'next',
                child: SizedBox(
                  height: height * floatingImageSizeRate,
                  child: Image.asset(nextArrow),
                ),
                //次の信号ボタンを押した時の処理
                onPressed: () async {
                  //次の信号に変更
                  nextOrBackCounter(true);
                  //音声を変更
                  if (isSound.value) {
                    (isGreen.value) ? setGreenSound() : setRedSound();
                    setAudioVolume();
                  }
                }
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}