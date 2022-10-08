import 'package:flutter/material.dart';
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

  late double width;
  late double height;
  late Locale locale;
  late String lang;
  late bool isPressed;
  late bool isGreen;    //true: Green, false: Red
  late bool isNew;
  late bool isFlash;
  late bool opaque;
  late bool isRedSound;
  late bool isGreenSound;
  late int countryNumber;
  late String countryCode;
  late List<String> countryList;
  late int waitTime;
  late int goTime;
  late int flashTime;
  late int countDown;
  late BannerAd myBanner;
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
      countDown = 0;
      countryNumber = 0;
      myBanner = AdmobService().getBannerAd();
    });
  }

  @override
  void didChangeDependencies() {
    "call didChangeDependencies".debugPrint();
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPlugin(context);
      initSettings();
    });
    setState((){
      width = context.width();
      height = context.height();
      locale = context.locale();
      lang = locale.languageCode;
      countryCode = locale.getCountryCode();
      countryList = countryCode.getCountryList();
      if (countryCode == "US") isNew = true;
    });
    "width: $width, height: $height".debugPrint();
    "Locale: $locale, CountryCode: $countryCode, CountryList: $countryList".debugPrint();
    _getSavedData();
    _loopRedSound();
  }

  @override
  void didUpdateWidget(oldWidget) {
    "call didUpdateWidget".debugPrint();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    "call deactivate".debugPrint();
    super.deactivate();
  }

  @override
  void dispose() {
    "call dispose".debugPrint();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myHomeAppBar(),
      body: Stack(alignment: Alignment.center,
        children: [
          backGroundImage(context, height, countryCode),
          Container(width: width, height: height, color: transpWhiteColor),
          Column(children: [
            const Spacer(flex: 1),
            signalImage(),
            const Spacer(flex: 1),
            pushButton(),
            const Spacer(flex: 1),
            adMobBannerWidget(context, myBanner),
          ]),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: context.admobHeight() * 0.8),
        child: Row(children: [
          const SizedBox(width: 32),
          selectOldAndNewButton(),
          const Spacer(),
          selectCountryButton(),
        ]),
      ),
    );
  }

  AppBar myHomeAppBar() =>
      AppBar(
        title: appTitleText(lang, context.appTitle()),
        backgroundColor: signalGrayColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: whiteColor, size: 32),
            onPressed: () => context.pushSettingsPage(),
          ),
        ],
      );

  Widget signalImage() =>
      (countryCode == "UK") ? ukSignal(height, isNew, isGreen, isFlash, opaque, countDown):
      (countryCode == "JP") ? jpSignal(height, isNew, isGreen, isFlash, opaque, countDown, goTime):
      usSignal(height, isNew, isGreen, isFlash, opaque, countDown);

  Widget pushButton() =>
      SizedBox(
        height: height * countryCode.buttonTotalHeightRate(isNew),
        child: Stack(alignment: Alignment.topCenter,
          children: [
            frameImage(height, isNew, isGreen, isPressed, countryCode),
            Column(children: [
              SizedBox(height: height * countryCode.buttonTopMarginRate(isNew)),
              ElevatedButton(
                style: pushButtonStyle(),
                onPressed: () => _pressedButton(),
                child: pushButtonImage(height, isNew, isPressed, countryCode),
              ),
            ])
          ]
        )
      );

  Widget selectOldAndNewButton() =>
      SizedBox(
        width: context.floatingButtonSize(),
        height: context.floatingButtonSize(),
        child: FloatingActionButton(
          foregroundColor: whiteColor,
          backgroundColor: blackColor,
          heroTag:'isNew',
          child: selectOldOrNew(context, countryCode, isNew, context.floatingFontSize()),
          onPressed: () async  => _isNewPressed(),
        )
      );

  Widget selectCountryButton() =>
      SizedBox(
        width: context.floatingButtonSize(),
        height: context.floatingButtonSize(),
        child: FloatingActionButton(
          backgroundColor: blackColor,
          heroTag:'country',
          child: selectCountryFlag(context, countryNumber.nextCountry(countryList)),
          onPressed: () async => _nextCountry(),
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
      await Future.delayed(Duration(seconds: waitTime.toInt())).then((_) async {
        //waitTime後に緑色点灯状態になる
        _setGreenState();
        for (int i = 0; i < goTime.toInt(); i++) {
          await Future.delayed(const Duration(seconds: 1))
              .then((_) async => _setCountDownState());
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
    if (countryCode == "US" && !isGreen && isNew) wait.speakText(context);
    Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
  }

  //カウントダウン
  _setCountDownState() async {
    setState(() => countDown = countDown - 1);
    "$countDown".debugPrint();
  }

  //ボタンが押された状態にする
  _setPressedButtonState() async {
    setState(() => isPressed = true);
    "pressedState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
  }

  //緑色状態にする
  _setGreenState() async {
    setState(() => isGreen = true);
    setState(() => countDown = (countryCode == "JP") ? goTime: goTime + flashTime);
    "greenState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
    await _stopSound();
    await _loopGreenSound();
  }

  //緑色点滅状態にする
  _setFlashGreenState(int i) async {
    if (i==0) {
      setState(() => isFlash = true);
      "flashState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
    }
    setState(() => opaque = !opaque);
    if (i % 2 == 1) {
      setState(() => countDown = (countDown - deltaFlash / 1000 * 2).toInt());
      "$countDown".debugPrint();
    }
  }

  //赤色点灯状態にする
  _setRedState() async {
    setState(() { isGreen = false; isFlash = false; isPressed = false; });
    "redState: isGreen: $isGreen, isFlash: $isFlash, isPressed: $isPressed".debugPrint();
    await _stopSound();
    await _loopRedSound();
  }

  //サウンドの停止
  _stopSound() async {
    await audioPlayer?.stop();
    "stop: sound".debugPrint();
  }

  //緑色時のサウンドをループ
  _loopGreenSound() async {
    if (isGreen && isGreenSound) {
      audioPlayer = await _audioPlayer.loop(
        countryCode.signalSoundG(isNew),
        volume: countryCode.signalVolume(isGreen, isNew)
      );
      "play: soundG".debugPrint();
    }
  }

  //赤色時のサウンドをループ
  _loopRedSound() async {
    if (!isGreen && isRedSound) {
      audioPlayer = await _audioPlayer.loop(
        countryCode.signalSoundR(isNew),
        volume: countryCode.signalVolume(isGreen, isNew)
      );
      "play: soundR".debugPrint();
    }
  }

  //新旧ボタンを押した時の処理
  _isNewPressed() async {
    setState(() => isNew = !isNew);
    await _stopSound();
    await ((isGreen) ? _loopGreenSound(): _loopRedSound());
    "nextDesign".debugPrint();
  }

  //国旗ボタンを押した時の処理
  _nextCountry() async {
    setState(() {
      countryNumber = (countryNumber + 1) % 3;
      countryCode = countryList[countryNumber];
      if (countryCode == "US") isNew = true;
      if (countryCode == "UK") isNew = false;
      if (countryCode == "JP") isNew = false;
    });
    await _stopSound();
    await ((isGreen) ? _loopGreenSound(): _loopRedSound());
    "nextCountry".debugPrint();
  }

  _getSavedData() {
    setState(() {
      waitTime = "wait".getSettingValueInt(waitTime_0);
      goTime = "go".getSettingValueInt(goTime_0);
      flashTime = "flash".getSettingValueInt(flashTime_0);
      isRedSound = "redSound".getSettingValueBool();
      isGreenSound = "greenSound".getSettingValueBool();
    });
    "Wait: $waitTime, Go: $goTime, Flash: $flashTime".debugPrint();
    "redSound: $isRedSound, greenSound: $isGreenSound".debugPrint();
  }
}