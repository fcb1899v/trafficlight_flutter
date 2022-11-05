import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';
import 'admob.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late int counter;
  late bool isPressed;
  late bool isGreen;    //true: Green, false: Red
  late bool isNew;
  late bool isFlash;
  late bool opaque;
  late bool isPedestrian;
  late bool isYellow;
  late bool isArrow;
  late int waitTime;
  late int goTime;
  late int flashTime;
  late int countDown;
  late bool isPremium;
  late bool isNoAds;
  late bool isTraffic;
  late AudioPlayer? audioPlayer;
  late AudioPlayer? buttonPlayer;
  final AudioCache _audioPlayer = AudioCache(fixedPlayer: AudioPlayer());
  final AudioCache _buttonPlayer = AudioCache(fixedPlayer: AudioPlayer());

  @override
  void initState() {
    "call initState".debugPrint();
    super.initState();
    setState(() {
      isPressed = false;
      isGreen = false;
      isNew = false;
      isFlash = false;
      opaque = false;
      isPedestrian = true;
      isYellow = false;
      isArrow = false;
      isPremium = false;
      isNoAds = false;
      isTraffic = false;
      countDown = 0;
    });
    initPlatformState();
    Purchases.addCustomerInfoUpdateListener((_) => updateCustomerStatus());
  }

  Future<void> initPlatformState() async {
    await Purchases.setDebugLogsEnabled(true);
    final PurchasesConfiguration configuration = PurchasesConfiguration(dotenv.get("REVENUE_CAT_IOS_API_KEY"));
    await Purchases.configure(configuration);
    await Purchases.enableAdServicesAttributionTokenCollection();
    Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
      'Received readyForPromotedProductPurchase event for productID: $productID'.debugPrint();
      try {
        final purchaseResult = await startPurchase.call();
        'Promoted purchase for productID ${purchaseResult.productIdentifier} completed, or product was'
        'already purchased. customerInfo returned is: ${purchaseResult.customerInfo}'.debugPrint();
      } on PlatformException catch (e) {
        'Error purchasing promoted product: ${e.message}'.debugPrint();
      }
    });
    if (!mounted) {
      "mounted".debugPrint();
      return;
    }
    updateCustomerStatus();
  }

  Future<void> updateCustomerStatus() async {
    final customerInfo = await Purchases.getCustomerInfo();
    final carsEntitlements = customerInfo.entitlements.active["signal_for_cars"];
    final noAdsEntitlements = customerInfo.entitlements.active["no_ads"];
    setState(() {
      isTraffic = carsEntitlements != null;
      isNoAds = noAdsEntitlements != null;
      if (isTraffic && isNoAds) isPremium = true;
    });
  }

  @override
  void didChangeDependencies() {
    "call didChangeDependencies".debugPrint();
    super.didChangeDependencies();
    final Locale locale = context.locale();
    final String lang = locale.languageCode;
    final String countryCode = locale.countryCode ?? "US";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPlugin(context);
      initSettings();
    });
    setState(() => counter = countryCode.getDefaultCounter());
    _getSavedData();
    _loopRedSound();
    "counter: $counter, Locale: $locale, Language: $lang, CountryCode: $countryCode".debugPrint();
  }

  @override
  void didUpdateWidget(oldWidget) {
    "call didUpdateWidget".debugPrint();
    super.didUpdateWidget(oldWidget);
    audioPlayer?.stop();
  }

  @override
  void deactivate() {
    "call deactivate".debugPrint();
    super.deactivate();
    audioPlayer?.stop();
  }

  @override
  void dispose() {
    "call dispose".debugPrint();
    super.dispose();
    audioPlayer?.stop();
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width();
    final height = context.height();
    final BannerAd myBanner = AdmobService().getBannerAd();
    "width: $width, height: $height".debugPrint();

    return Scaffold(
      appBar: myHomeAppBar(context, counter),
      body: Stack(alignment: Alignment.center,
        children: [
          backGroundImage(context, height, counter),
          Container(width: width, height: height, color: backGroundColor[counter]),
          Column(
            children: [
            const Spacer(flex: 1),
            signalImage(context, counter, countDown, goTime + flashTime, isGreen, isFlash, opaque, isPedestrian, isYellow, isArrow),
            const Spacer(flex: 1),
            pushButton(height),
            const Spacer(flex: 1),
            adMobBannerWidget(context, myBanner, isNoAds),
          ]),
        ],
      ),
      floatingActionButton: SizedBox(
        child: Column(children: [
          const Spacer(flex: 3),
          if (isTraffic) Row(children: [
          //if (isTraffic || kDebugMode) Row(children: [
            const Spacer(),
            changeModeButton(height),
          ]),
          const Spacer(flex: 2),
          Row(children: [
            const SizedBox(width: 32),
            changeSignalButton(height, false),
            const Spacer(),
            changeSignalButton(height, true),
          ]),
          SizedBox(height: context.admobHeight() * 0.8),
        ])
      ),
    );
  }

  Widget pushButton(double height) =>
      Stack(alignment: Alignment.topCenter,
        children: [
          pushButtonFrame(context, counter, isGreen, isFlash, opaque, isPressed)      ,
          Column(children: [
            SizedBox(height: height * buttonTopMarginRate[counter]),
            ElevatedButton(
              style: pushButtonStyle(),
              onPressed: () => _pressedButton(),
              child: SizedBox(
                height: height * buttonHeightRate[counter],
                child: Image(image: AssetImage(counter.pushButtonImageString(isGreen, isPressed)))
              ),
            ),
          ]),
          frameLabels(context, counter, isPressed, isGreen)
        ]
      );

  Widget changeSignalButton(double height, bool isNext) =>
      SizedBox(
        width: height * floatingButtonSizeRate,
        height: height * floatingButtonSizeRate,
        child: FloatingActionButton(
          foregroundColor: whiteColor,
          backgroundColor: blackColor,
          heroTag:'next_$isNext',
          child: SizedBox(
            height: height * floatingImageSizeRate,
            child: Image.asset(isNext ? nextArrow: backArrow),
          ),
          onPressed: () async  => isNext ? _nextCounter(): _backCounter(),
        )
      );

  Widget changeModeButton(double height) =>
      SizedBox(
        width: height * floatingButtonSizeRate,
        height: height * floatingButtonSizeRate,
        child: FloatingActionButton(
          backgroundColor: blackColor,
          heroTag:'mode',
          child: Icon(Icons.cached, color: whiteColor, size: height * floatingIconSizeRate),
          onPressed: () async => _changeMode(),
        )
      );

  ///Button Action
  //ボタンを押した時の操作
  _pressedButton() async {
    //ボタンを押した時の音
    _pressedButtonSound();
    //赤色点灯かつボタンが押されていないときに発動
    if (!isGreen && !isFlash && !isPressed) {
      //各種パラメータの取得
      _getSavedData();
      //ボタンが押された状態になる
      _setPressedButtonState();
      await Future.delayed(Duration(seconds: (waitTime - yellowTime))).then((_) async {
        _setYellowState();
        for (int i = 0; i < yellowTime * 1000 ~/ deltaFlash + 1; i++) {
          await Future.delayed(const Duration(milliseconds: deltaFlash))
              .then((_) async => _setFlashYellowState());
        }
      });
      await Future.delayed(const Duration(seconds: 0)).then((_) async {
        //waitTime後に緑色点灯状態になる
        _setGreenState();
        for (int i = 0; i < goTime; i++) {
          await Future.delayed(const Duration(seconds: 1)).then((_) async {
            _setCountDownState();
            if (i == arrowTime - 1) _setVanishArrowState();
          });
        }
        //greenTime後に緑色点滅状態になる
        for (int i = 0; i < flashTime * 1000 ~/ deltaFlash + 1; i++) {
          await Future.delayed(const Duration(milliseconds: deltaFlash))
              .then((_) async => _setFlashGreenState(i));
        }
      });
      //greenTime後に赤色点灯状態になる
      await Future.delayed(const Duration(seconds: 0))
          .then((_) async => _setRedState());
    }
  }

  //ボタンを押した時の音
  _pressedButtonSound() async {
    buttonPlayer = await _buttonPlayer.play(buttonSound, volume: buttonVolume);
    if (counter == 0 && !isGreen) "wait".speakText(context);
    Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
  }

  //カウントダウン
  _setCountDownState() async {
    setState(() => countDown = countDown - 1);
    "countDown: $countDown".debugPrint();
  }

  //ボタンが押された状態にする
  _setPressedButtonState() async {
    setState(() => isPressed = true);
    "pressedState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
  }

  //黄色状態にする
  _setYellowState() async {
    setState(() => isYellow = true);
    setState(() => isGreen = false);
    "yellowState: isGreen: $isGreen, isYellow: $isYellow".debugPrint();
  }

  //緑色状態にする
  _setGreenState() async {
    setState(() => isGreen = true);
    setState(() => isYellow = false);
    setState(() => isArrow = true);
    setState(() => countDown = goTime + flashTime);
    "greenState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
    "countDown: $countDown".debugPrint();
    await _stopSound();
    await _loopGreenSound();
  }

  //緑色点滅状態にする
  _setFlashGreenState(int i) async {
    if (i==0) {
      setState(() => isFlash = true);
      "flashState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed, isYellow: $isYellow, isArrow: $isArrow".debugPrint();
    }
    setState(() => opaque = !opaque);
    if (i % 2 == 1) {
      setState(() => countDown = (countDown - deltaFlash / 1000 * 2).toInt());
      "countDown: $countDown, opaque: $opaque".debugPrint();
    }
  }

  //黄色点滅状態にする
  _setFlashYellowState() async {
    setState(() => opaque = !opaque);
    "yellowFlashState: opaque: $opaque".debugPrint();
  }

  //赤色点灯状態にする
  _setRedState() async {
    setState(() { isGreen = false; isFlash = false; isPressed = false; });
    "redState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed, isYellow: $isYellow, isArrow: $isArrow".debugPrint();
    await _stopSound();
    await _loopRedSound();
  }

  //右折矢印の非表示
  _setVanishArrowState() async {
    setState(() => isArrow = false);
    "vanishArrowState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed, isYellow: $isYellow, isArrow: $isArrow".debugPrint();
  }

  //サウンドの停止
  _stopSound() async {
    await audioPlayer?.stop();
    "stop: sound".debugPrint();
  }

  //緑色時のサウンドをループ
  _loopGreenSound() async {
    if (isGreen) {
      audioPlayer = await _audioPlayer.loop(soundGreen[counter], volume: musicVolume);
      "play: soundG".debugPrint();
    }
  }

  //赤色時のサウンドをループ
  _loopRedSound() async {
    if (!isGreen) {
      audioPlayer = await _audioPlayer.loop(soundRed[counter], volume: musicVolume);
      "play: soundR".debugPrint();
    }
  }

  //次の信号ボタンを押した時の処理
  _nextCounter() async {
    setState(() => counter = (counter + 1) % countryList.length);
    await _stopSound();
    await ((isGreen) ? _loopGreenSound(): _loopRedSound());
    "nextCounter".debugPrint();
  }

  //前の信号ボタンを押した時の処理
  _backCounter() async {
    setState(() => counter = (counter - 1) % countryList.length );
    await _stopSound();
    await ((isGreen) ? _loopGreenSound(): _loopRedSound());
    "backCounter".debugPrint();
  }

  _changeMode() async {
    setState(() => isPedestrian = !isPedestrian);
    "changeMode".debugPrint();
  }

  _getSavedData() {
    setState(() {
      waitTime = "wait".getSettingValueInt(waitTime_0);
      goTime = "go".getSettingValueInt(goTime_0);
      flashTime = "flash".getSettingValueInt(flashTime_0);
    });
    "Wait: $waitTime, Go: $goTime, Flash: $flashTime".debugPrint();
  }
}