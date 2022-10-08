import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'constant.dart';


extension LocaleExt on Locale {

  //this is diffHour
  String getCountryCode() {
    "Timezone: ${DateTime.now().timeZoneName}".debugPrint();
    return ("$this" == "en" &&  DateTime.now().timeZoneName == "UTC") ? "UK":
           ("$this" == "ja") ? "JP": "US";
  }
}

extension ContextExt on BuildContext {

  ///Common
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///LETS SIGNAL
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String waitTime() => AppLocalizations.of(this)!.waitTime;
  String goTime() => AppLocalizations.of(this)!.goTime;
  String flashTime() => AppLocalizations.of(this)!.flashTime;
  String redSound() => AppLocalizations.of(this)!.redSound;
  String greenSound() => AppLocalizations.of(this)!.greenSound;
  String toSettings() => AppLocalizations.of(this)!.toSettings;
  String toOn() => AppLocalizations.of(this)!.toOn;
  String toOff() => AppLocalizations.of(this)!.toOff;
  String toNew() => AppLocalizations.of(this)!.toNew;
  String toOld() => AppLocalizations.of(this)!.toOld;
  String oldOrNew(bool isNew) => (isNew) ? toOld(): toNew();
}

extension StringExt on String {

  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  void pushPage(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(this, (_) => false);

  void musicAudio() async {
    AudioPlayer audioPlayer = AudioPlayer();
    debugPrint();
    await audioPlayer.stop();
    await audioPlayer.setVolume(musicVolume);
    await audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    await audioPlayer.play(this);
  }

  void buttonAudio() async {
    AudioPlayer audioPlayer = AudioPlayer();
    debugPrint();
    await audioPlayer.stop();
    await audioPlayer.setVolume(buttonVolume);
    await audioPlayer.play(this);
  }

  Future<void> speakText(BuildContext context) async {
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(this);
  }

  //this is key
  int getSettingValueInt(int defaultValue) =>
      Settings.getValue<double>("key_$this", defaultValue: defaultValue.toDouble())!.toInt();

  bool getSettingValueBool() =>
      Settings.getValue("key_$this", defaultValue: true)!;

  //this is countryCode
  List<String> getCountryList() =>
      (this == "UK") ? ukList:
      (this == "JP") ? jpList:
      usList;

  double buttonTotalHeightRate(bool isNew) =>
      (this == "UK") ? isNew.ukButtonTotalHeightRate():
      (this == "JP") ? isNew.jpButtonTotalHeightRate():
      isNew.usButtonTotalHeightRate();

  double buttonTopMarginRate(bool isNew) =>
      (this == "UK") ? isNew.ukButtonTopMarginRate():
      (this == "JP") ? isNew.jpButtonTopMarginRate():
      isNew.usButtonTopMarginRate();

  String signalSoundG(bool isNew) =>
      (this == "UK") ? isNew.ukSignalSoundG():
      (this == "JP") ? isNew.jpSignalSoundG():
      isNew.usSignalSoundG();

  String signalSoundR(bool isNew) =>
      (this == "UK") ? isNew.ukSignalSoundR():
      (this == "JP") ? isNew.jpSignalSoundR():
      isNew.usSignalSoundR();

  double signalVolume(bool isGreen, bool isNew) =>
      (this == "UK" && isGreen && isNew) ? isNew.ukSignalVolume(isGreen):
      (this == "JP") ? isNew.jpSignalVolume(isGreen):
      isNew.usSignalVolume();

  String countryFlag() =>
      (this == "UK") ? ukFlag:
      (this == "JP") ? jpFlag:
      usFlag;
}


extension BoolExt on bool {

  ///this is isNew
  //Frame Image File
  String jpFrameImage() => (this) ? jpNewFrame: jpOldFrame;
  String usFrameImage() => (this) ? usNewFrame: usOldFrame;
  String ukFrameImage(bool isGreen, bool isPressed) =>
      (this && isGreen) ? ukNewFrameG:
      (this && !isGreen) ? ukNewFrameR:
      (isPressed) ? ukOldFrameOn:
      ukOldFrameOff;

  //Button Image File
  String jpButtonImage() => (this) ? jpNewButton: jpOldButton;
  String usButtonImage(bool isPressed) =>
      (!this) ? usOldButton:
      (isPressed) ? usNewButtonOn:
      usNewButtonOff;
  String ukButtonImage(bool isPressed) =>
      (!this) ? ukOldButton:
      (isPressed) ? ukNewButtonOn:
      ukNewButtonOff;

  //Signal Image Height Rate
  double usSignalHeightRate() =>
      (this) ? usNewSignalHeightRate: usOldSignalHeightRate;
  double ukSignalHeightRate() =>
      (this) ? ukNewSignalHeightRate: ukOldSignalHeightRate;
  double jpSignalHeightRate() =>
      (this) ? jpNewSignalHeightRate: jpOldSignalHeightRate;

  //Push Button Total Height Rate
  double usButtonTotalHeightRate() =>
      (this) ? usNewButtonTotalHeightRate: usOldButtonTotalHeightRate;
  double ukButtonTotalHeightRate() =>
      (this) ? ukNewButtonTotalHeightRate: ukOldButtonTotalHeightRate;
  double jpButtonTotalHeightRate() =>
      (this) ? jpNewButtonTotalHeightRate: jpOldButtonTotalHeightRate;

  //Button Image Height Rate
  double usButtonHeightRate() => (this) ? usNewButtonHeightRate: usOldButtonHeightRate;
  double ukButtonHeightRate() => (this) ? ukNewButtonHeightRate: ukOldButtonHeightRate;
  double jpButtonHeightRate() => (this) ? jpNewButtonHeightRate: jpOldButtonHeightRate;

  //Button Top Margin
  double usButtonTopMarginRate() => (this) ? usNewButtonTopMarginRate: usOldButtonTopMarginRate;
  double ukButtonTopMarginRate() => (this) ? ukNewButtonTopMarginRate: ukOldButtonTopMarginRate;
  double jpButtonTopMarginRate() => (this) ? jpNewButtonTopMarginRate: jpOldButtonTopMarginRate;

  //Frame Image Height Rate
  double usFrameHeightRate() => (this) ? usNewFrameHeightRate: usOldFrameHeightRate;
  double ukFrameHeightRate() => (this) ? ukNewFrameHeightRate: ukOldFrameHeightRate;
  double jpFrameHeightRate() => (this) ? jpNewFrameHeightRate: jpOldFrameHeightRate;

  //jp Label Margin
  double jpLabelTopMarginRate() => this ? jpNewLabelTopMarginRate: jpOldLabelTopMarginRate;
  double jpLabelMiddleMarginRate() => this ? jpNewLabelMiddleMarginRate: jpOldLabelMiddleMarginRate;

  //Green Sound
  String usSignalSoundG() => (this) ? usSoundNewG: usSoundOldG;
  String ukSignalSoundG() => (this) ? ukSoundNewG: ukSoundOldG;
  String jpSignalSoundG() => (this) ? jpSoundNewG: jpSoundOldG;

  //Red Sound
  String usSignalSoundR() => (this) ? usSoundNewR: usSoundOldR;
  String ukSignalSoundR() => (this) ? ukSoundNewR: ukSoundOldR;
  String jpSignalSoundR() => (this) ? jpSoundNewR: jpSoundOldR;

  //Sound Volume
  double usSignalVolume() => (this) ? 1: 0; //this is isNew
  double ukSignalVolume(bool isGreen) => (this && isGreen) ? 1: 0; //this is isNew
  double jpSignalVolume(bool isGreen) => (isGreen) ? 1: 0; //this is isGreen

  // this is isPressed
  String jpFrameMessage(bool isGreen, bool isNew, bool isUpper) =>
      (!isGreen && this && isUpper) ? "おまちください":
      (!isNew && !isGreen && !this && !isUpper) ? "おしてください":
      (isNew && !isGreen && !this && !isUpper) ? "ふれてください":
      "";

  //this is isGreen
  String usSignalImage(bool isFlash, bool isNew, bool opaque) =>
      (this && !isFlash && isNew) ? usNewSignalG:
      (isNew && isFlash && opaque) ? usNewSignalOff:
      (isNew) ? usNewSignalR:
      (this && !isFlash && !isNew) ? usOldSignalG:
      (isFlash && opaque) ? usOldSignalOff:
      usOldSignalR;

  String jpSignalImage(bool isFlash, bool isNew, bool opaque) =>
      (!this && isNew) ? jpNewSignalR:
      (isNew && isFlash && opaque) ? jpNewSignalOff:
      (isNew) ? jpNewSignalG:
      (!this) ? jpOldSignalR:
      (isFlash && opaque) ? jpOldSignalOff:
      jpOldSignalG;

  String ukSignalImage(bool isFlash, bool isNew, bool opaque, int countDown) =>
      (!this && isNew) ? ukNewSignalR:
      (isFlash && countDown < 2 && isNew) ? ukNewSignalOff:
      (isNew) ? ukNewSignalG:
      (!this) ? ukOldSignalR:
      (isFlash && opaque) ? ukOldSignalOff:
      ukOldSignalG;
}


extension IntExt on int {

  //this is countDown
  List<bool> jpCountMeterColor(int goTime) =>
    (this / goTime > 0.875) ? [true, true, true, true, true, true, true, true]:
    (this / goTime > 0.750) ? [false, true, true, true, true, true, true, true]:
    (this / goTime > 0.625) ? [false, false, true, true, true, true, true, true]:
    (this / goTime > 0.500) ? [false, false, false, true, true, true, true, true]:
    (this / goTime > 0.375) ? [false, false, false, false, true, true, true, true]:
    (this / goTime > 0.250) ? [false, false, false, false, false, true, true, true]:
    (this / goTime > 0.125) ? [false, false, false, false, false, false, true, true]:
    (this / goTime > 0) ? [false, false, false, false, false, false, false, true]:
    [false, false, false, false, false, false, false, false];

  //this is countDown
  List<Color> jpGreenMeterList(int i) => List.filled(i, greenColor);
  List<Color> jpGrayMeterList(int i) => List.filled(i, signalGrayColor);

  int countDownNumber(bool isFlash, bool is10) =>
      (is10 && this > 9 && isFlash) ? this ~/ 10:
      (!is10 && isFlash) ? this % 10:
      8;

  int isOne() => (this == 1) ? this: 0;

  Color countDownColor(Color color, bool isFlash, bool is10) =>
      (((is10 && this > 9) || !is10) && isFlash) ? color: signalGrayColor;

  //this is countryNumber
  String nextCountry(List<String> countryList) =>
      countryList[(this + 1) % 3];

}

extension DoubleExt on double {

  //this is width
  double settingsSidePadding() => this < 600 ? 10: this / 2 - 290;

  //this is height
  double floatingButtonSize() => this / 14;
  double floatingFontSize() => this / 60;
  double flagSize() => this / 35;
  double jpFlagPadding() => flagSize() * 4;

  //Admob
  double admobHeight() => (this < 750) ? 50: (this < 1000) ? 50 + (this - 750) / 5: 100;
  double admobWidth() => this - 100;
}

