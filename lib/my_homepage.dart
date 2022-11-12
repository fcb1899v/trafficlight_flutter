import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'main.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'viewmodel.dart';
import 'admob.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();
    final BannerAd myBanner = AdmobService().getBannerAd();

    final List<Locale> locales = WidgetsBinding.instance.window.locales;
    final String countryCode = locales.first.countryCode ?? "US";
    final counter = useState(countryCode.getDefaultCounter());

    final isPressed = useState(false);
    final isGreen = useState(false);
    final isYellow = useState(false);
    final isArrow = useState(false);
    final isFlash = useState(false);
    final opaque = useState(false);
    final isPedestrian = useState(true);

    final plan = ref.read(planProvider.notifier);
    final isCarsProvider = ref.watch(planProvider).isCars;
    final isNoAdsProvider = ref.watch(planProvider).isNoAds;
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isCars = useState("cars".getSettingsValueBool(false));
    final isNoAds = useState("noAds".getSettingsValueBool(false));

    final countDown = useState(0);
    final waitTime = useState("wait".getSettingsValueInt(waitTime_0));
    final goTime = useState("go".getSettingsValueInt(goTime_0));
    final flashTime = useState("flash".getSettingsValueInt(flashTime_0));
    final yellowTime = useState(yellowTime_0);
    final arrowTime = useState(arrowTime_0);

    final audioPlayer = useState(AudioPlayer());
    final buttonPlayer = useState(AudioPlayer());
    final audioSound = useState(soundRed[counter.value]);
    final flutterTts = useState(FlutterTts());

    useEffect(() {
      "width: $width, height: $height".debugPrint();
      "counter: ${counter.value}, CountryCode: ${locales.first.countryCode}".debugPrint();
      "isPremium: ${isPremium.value}, isCars: ${isCars.value}, isNoAds: ${isNoAds.value}".debugPrint();
      "waitTIme: ${waitTime.value}, goTime: ${goTime.value}, flashTime: ${flashTime.value}".debugPrint();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initPlugin(context);
        initSettings();
        await Purchases.setDebugLogsEnabled(true);
        await Purchases.configure(PurchasesConfiguration(dotenv.get("REVENUE_CAT_IOS_API_KEY")));
        await Purchases.enableAdServicesAttributionTokenCollection();
        Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
          'productID: $productID'.debugPrint();
          try {
            final purchaseResult = await startPurchase.call();
            "productID ${purchaseResult.productIdentifier}".debugPrint();
            "customerInfo: ${purchaseResult.customerInfo}".debugPrint();
          } on PlatformException catch (e) {
            'Error: ${e.message}'.debugPrint();
          }
        });

        if (!(isPremium.value)) {
          final pref = await SharedPreferences.getInstance();
          final restoredInfo = await Purchases.restorePurchases();
          "restoredInfo: $restoredInfo".debugPrint();
          isCars.value = restoredInfo.entitlements.active["signal_for_cars"] != null;
          isNoAds.value = restoredInfo.entitlements.active["no_ads"] != null;
          if (isCars.value && isNoAds.value) isPremium.value = true;
          "isPremium: ${isPremium.value}, isCars: ${isCars.value}, isNoAds: ${isNoAds.value}".debugPrint();
          await pref.setBool('key_cars', isCars.value);
          await pref.setBool('key_noAds', isNoAds.value);
          await pref.setBool('key_premium', isPremium.value);
        }
        plan.setCurrentPlan(isCars.value, isNoAds.value, isPremium.value);
        "isPremiumProvider: $isPremiumProvider, isCarsProvider: $isCarsProvider, isNoAdsProvider: $isNoAdsProvider".debugPrint();

        await flutterTts.value.setLanguage("en-US");
        await flutterTts.value.setVolume(musicVolume);
        await buttonPlayer.value.setVolume(buttonVolume);
        await buttonPlayer.value.setSourceAsset(buttonSound);
        await audioPlayer.value.setVolume(musicVolume);
        await audioPlayer.value.setReleaseMode(ReleaseMode.loop);
        await audioPlayer.value.setSourceAsset(audioSound.value);
        "redSound: play: ${audioSound.value}".debugPrint();
      });
      return () => audioPlayer.value.release();
    }, const []);

    setGreenSound() async {
      await audioPlayer.value.stop();
      "redSound: stop".debugPrint();
      audioSound.value = soundGreen[counter.value];
      await audioPlayer.value.setSourceAsset(audioSound.value);
      await audioPlayer.value.resume();
      "greenSound: play: ${soundGreen[counter.value]}".debugPrint();
    }

    setRedSound() async {
      await audioPlayer.value.stop();
      "greenSound: stop".debugPrint();
      audioSound.value = soundRed[counter.value];
      await audioPlayer.value.setSourceAsset(audioSound.value);
      await audioPlayer.value.resume();
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

    pushButtonEffect() async {
      if (counter.value == 0 && !isGreen.value) await flutterTts.value.speak("wait");
      await buttonPlayer.value.resume();
      "button: $buttonSound".debugPrint();
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    }

    flashGreenState(int i) {
      if (i == 0) {
        isFlash.value = true;
        "greenFlashState: isGreen: ${isGreen.value}, isFlash: ${isFlash.value}".debugPrint();
      }
      opaque.value = !opaque.value;
      "opaque: ${opaque.value}".debugPrint();
      if (i % 2 == 1) {
        countDown.value = (countDown.value - deltaFlash / 1000 * 2).toInt();
        "countDown: ${countDown.value}".debugPrint();
      }
    }

    calcCountDown() async {
      countDown.value = goTime.value + flashTime.value;
      "countDown: ${countDown.value}".debugPrint();
      await setGreenSound();
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(appBarHeight),
        child: AppBar(
          title: titleText(context, context.appTitle()),
          backgroundColor: signalGrayColor,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: whiteColor, size: 32),
              onPressed: () async {
                context.pushSettingsPage();
              },
            ),
          ],
        ),
      ),
      body: Stack(alignment: Alignment.center,
        children: [
          backGroundImage(context, height, counter.value),
          Container(width: width, height: height, color: backGroundColor[counter.value]),
          Column(
            children: [
            const Spacer(flex: 1),
            signalImage(context, counter.value, countDown.value, goTime.value + flashTime.value, isGreen.value, isFlash.value, opaque.value, isPedestrian.value, isYellow.value, isArrow.value),
            const Spacer(flex: 1),
            Stack(alignment: Alignment.topCenter,
              children: [
                pushButtonFrame(context, counter.value, isGreen.value, isFlash.value, opaque.value, isPressed.value)      ,
                Column(children: [
                  SizedBox(height: height * buttonTopMarginRate[counter.value]),
                  ElevatedButton(
                    style: pushButtonStyle(),
                    onPressed: () async {
                      //ボタンを押した時の効果
                      await pushButtonEffect();
                      //赤色点灯かつボタンが押されていないときに発動
                      if (!isGreen.value && !isFlash.value && !isPressed.value) {
                        //各種パラメータの取得
                        await setTimeParameter();
                        //ボタンが押された状態にする
                        isPressed.value = true;
                        "isPressedState: isPressed: ${isPressed.value}".debugPrint();
                        await Future.delayed(Duration(seconds: (waitTime.value - yellowTime.value - arrowTime.value))).then((_) async {
                          //黄色点灯状態にする
                          isGreen.value = false; isYellow.value = true;
                          "yellowState: isGreen: ${isGreen.value}, isYellow: ${isYellow.value}".debugPrint();
                        });
                        await Future.delayed(Duration(seconds: yellowTime.value)).then((_) async {
                          //矢印点灯状態にする
                          isYellow.value = false; isArrow.value = true;
                          "arrowState: isYellow: ${isYellow.value}, isArrow: ${isArrow.value}".debugPrint();
                        });
                        await Future.delayed(Duration(seconds: arrowTime.value)).then((_) async {
                          //緑色点灯状態にする
                          isGreen.value = true; isYellow.value = false; isArrow.value = false;
                          "greenState: isGreen: ${isGreen.value}, isYellow: ${isYellow.value}, isArrow: ${isArrow.value}".debugPrint();
                          //countDownの計算
                          await calcCountDown();
                          //greenTime後に緑色点滅状態になる
                          for (int i = 0; i < flashTime.value * 1000 ~/ deltaFlash + 1; i++) {
                            //緑色点滅状態にする
                            await Future.delayed(const Duration(milliseconds: deltaFlash))
                                .then((_) async => flashGreenState(i));
                          }
                        });
                        //赤色点灯状態になる
                        await Future.delayed(const Duration(seconds: 0)).then((_) async {
                          isGreen.value = false; isFlash.value = false; isPressed.value = false;
                          "redState: isGreen: ${isGreen.value}, isFlash: ${isFlash.value}, isPressed: ${isPressed.value}".debugPrint();
                          await setRedSound();
                       });
                      }
                    },
                    child: SizedBox(
                      height: height * buttonHeightRate[counter.value],
                      child: Image(image: AssetImage(counter.value.pushButtonImageString(isGreen.value, isPressed.value)))
                    ),
                  ),
                ]),
                frameLabels(context, counter.value, isPressed.value, isGreen.value)
              ]
            ),
            const Spacer(flex: 1),
            adMobBannerWidget(context, myBanner, isNoAdsProvider),
          ]),
        ],
      ),
      floatingActionButton: SizedBox(
        child: Column(children: [
          const Spacer(flex: 3),
          if (isCarsProvider) Row(children: [
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
            const SizedBox(width: 32),
            SizedBox(
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
                  (isGreen.value) ? setGreenSound(): setRedSound();
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
                  (isGreen.value) ? setGreenSound(): setRedSound();
                }
              ),
            ),
          ]),
          SizedBox(height: context.admobHeight() * 0.8),
        ]),
      ),
    );
  }
}