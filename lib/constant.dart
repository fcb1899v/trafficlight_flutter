import 'package:flutter/material.dart';

///Signal Number
const int signalNumber = 7;

///App Name
const String appTitle = "LETS SIGNAL";
const String appTitleImage = "assets/images/letsSignal.png";
const double appBarHeight = 56;

///Time
const int waitTime_0 = 8;     //seconds
const int goTime_0 = 8;       //seconds
const int flashTime_0 = 8;    //seconds
const int yellowTime_0 = 3;     //seconds
const int arrowTime_0 = 3;      //seconds
const int deltaFlash = 500;   //milliseconds

///Vibration
const int vibTime = 200;
const int vibAmp = 128;

///Color
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;
const Color signalGrayColor = Color.fromRGBO(35, 35, 35, 1);    //#232323
const Color transpGrayColor = Color.fromRGBO(180, 180, 180, 0.9);
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.9);
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.9);
const Color edgeColor1 = Color.fromRGBO(180, 180, 180, 1);      //#b4b4b4
const Color edgeColor2 = Color.fromRGBO(230, 230, 230, 1);      //#e6e6e6
const Color amberColor = Colors.amber;      //#fad25a
const Color yellowColor = Color.fromRGBO(250, 210, 90, 1);      //#fad25a
const Color darkYellowColor = Color.fromRGBO(190, 140, 60, 1);  //#be8c3c
const Color orangeColor = Color.fromRGBO(209, 130, 64, 1);      //#d18240
const Color greenColor = Color.fromRGBO(87, 191, 163, 1);       //#57BFA3
const Color redColor = Color.fromRGBO(200, 77, 62, 1);          //#C84D3E
const List<Color> backGroundColor = [
  transpGrayColor,
  transpGrayColor,
  transpGrayColor,
  transpGrayColor,
  transpWhiteColor,
  transpWhiteColor,
  transpGrayColor,
];

/// Sound
const String buttonSound = "audios/pon.mp3";
const String audioFile = "audios/sound_";
const String noneSound = "audios/sound_none.mp3";
const double musicVolume = 1;
const double buttonVolume = 1;
// Green
const List<String> soundGreen = [
  "${audioFile}us_g.mp3",
  "${audioFile}none.mp3",
  "${audioFile}uk_g.mp3",
  "${audioFile}none.mp3",
  "${audioFile}jp_new.mp3",
  "${audioFile}jp_old.mp3",
  "${audioFile}us_g.mp3"
];
// Red
const List<String> soundRed = [
  "${audioFile}us_r.mp3",
  "${audioFile}none.mp3",
  "${audioFile}none.mp3",
  "${audioFile}none.mp3",
  "${audioFile}none.mp3",
  "${audioFile}none.mp3",
  "${audioFile}us_r.mp3"
];

///Image Folder
//Pedestrian
const String pedestrianUSImageAssets = "assets/images/pedestrian/us/";
const String pedestrianUKImageAssets = "assets/images/pedestrian/uk/";
const String pedestrianJPImageAssets = "assets/images/pedestrian/jp/";
const String pedestrianAUImageAssets = "assets/images/pedestrian/au/";
//Traffic
const String trafficUSImageAssets = "assets/images/traffic/us/";
const String trafficUKImageAssets = "assets/images/traffic/uk/";
const String trafficJPImageAssets = "assets/images/traffic/jp/";
const String trafficAUImageAssets = "assets/images/traffic/au/";

///Background
const String nextArrow = "assets/images/nextArrow.png";
const String backArrow = "assets/images/backArrow.png";
const List<String> countryFlag = [
  "${pedestrianUSImageAssets}flag_us.png",
  "${pedestrianUSImageAssets}flag_us.png",
  "${pedestrianUKImageAssets}flag_uk.png",
  "${pedestrianUKImageAssets}flag_uk.png",
  "${pedestrianJPImageAssets}flag_jp.png",
  "${pedestrianJPImageAssets}flag_jp.png",
  "${pedestrianAUImageAssets}flag_au.png",
];

///Button Frame
const double frameHeightRate = 0.40;
const List<double> frameTopPaddingRate = [0, 0, 0, 0, 0.01, 0.02, 0];
const List<double> frameBottomPaddingRate = [0, 0.08, 0, 0, 0.01, 0.02, 0];
const List<double> labelTopMarginRate = [0, 0, 0, 0, 0.085, 0.10, 0];
const List<double> labelMiddleMarginRate = [0, 0, 0, 0, 0.14, 0.135, 0];
const List<double> labelHeightRate = [0, 0, 0, 0, 0.045, 0.045, 0];
const List<double> labelWidthRate = [0, 0, 0, 0, 0.2, 0.2, 0];
const List<double> labelFontSizeRate = [0, 0, 0, 0, 0.025, 0.025, 0];
// Red & Waiting
const List<String> buttonFrameWaitString = [
  "${pedestrianUSImageAssets}frame_us_new.png",
  "${pedestrianUSImageAssets}frame_us_old.png",
  "${pedestrianUKImageAssets}frame_uk_new_r.png",
  "${pedestrianUKImageAssets}frame_uk_old_on.png",
  "${pedestrianJPImageAssets}frame_jp_new.png",
  "${pedestrianJPImageAssets}frame_jp_old.png",
  "${pedestrianAUImageAssets}frame_au_on.png"
];
// Red
const List<String> buttonFrameRedString = [
  "${pedestrianUSImageAssets}frame_us_new.png",
  "${pedestrianUSImageAssets}frame_us_old.png",
  "${pedestrianUKImageAssets}frame_uk_new_r.png",
  "${pedestrianUKImageAssets}frame_uk_old_off.png",
  "${pedestrianJPImageAssets}frame_jp_new.png",
  "${pedestrianJPImageAssets}frame_jp_old.png",
  "${pedestrianAUImageAssets}frame_au_off.png"
];
// Green
const List<String> buttonFrameGreenString = [
  "${pedestrianUSImageAssets}frame_us_new.png",
  "${pedestrianUSImageAssets}frame_us_old.png",
  "${pedestrianUKImageAssets}frame_uk_new_g.png",
  "${pedestrianUKImageAssets}frame_uk_old_off.png",
  "${pedestrianJPImageAssets}frame_jp_new.png",
  "${pedestrianJPImageAssets}frame_jp_old.png",
  "${pedestrianAUImageAssets}frame_au_off.png"
];
// Off
const List<String> buttonFrameOffString = [
  "${pedestrianUSImageAssets}frame_us_new.png",
  "${pedestrianUSImageAssets}frame_us_old.png",
  "${pedestrianUKImageAssets}frame_uk_new_off.png",
  "${pedestrianUKImageAssets}frame_uk_old_off.png",
  "${pedestrianJPImageAssets}frame_jp_new.png",
  "${pedestrianJPImageAssets}frame_jp_old.png",
  "${pedestrianAUImageAssets}frame_au_off.png"
];

///Push Button
const List<double> buttonHeightRate = [0.13, 0.11, 0.05, 0.04, 0.115, 0.08, 0.15];
const List<double> buttonTopMarginRate = [0.225, 0.29, 0.328, 0.325, 0.143, 0.17, 0.22];
//On
const List<String> pushButtonOnString = [
  "${pedestrianUSImageAssets}button_us_new_on.png",
  "${pedestrianUSImageAssets}button_us_old.png",
  "${pedestrianUKImageAssets}button_uk_new_on.png",
  "${pedestrianUKImageAssets}button_uk_old.png",
  "${pedestrianJPImageAssets}button_jp_new.png",
  "${pedestrianJPImageAssets}button_jp_old.png",
  "${pedestrianAUImageAssets}button_au.png"
];
//Off
const List<String> pushButtonOffString = [
  "${pedestrianUSImageAssets}button_us_new_off.png",
  "${pedestrianUSImageAssets}button_us_old.png",
  "${pedestrianUKImageAssets}button_uk_new_off.png",
  "${pedestrianUKImageAssets}button_uk_old.png",
  "${pedestrianJPImageAssets}button_jp_new.png",
  "${pedestrianJPImageAssets}button_jp_old.png",
  "${pedestrianAUImageAssets}button_au.png"
];

///Pedestrian Signal
const double signalHeightRate = 0.35;
const List<double> pedestrianSignalPaddingRate = [0.03, 0.06, 0.03, 0.015, 0.015, 0.015, 0.015];
const List<double> trafficSignalPaddingRate = [0.01, 0, 0.01, 0.01, 0.04, 0.04, 0.01];
const String netImage = "${pedestrianUSImageAssets}net.png";
//Green
const List<String> pedestrianSignalGreenString = [
  "${pedestrianUSImageAssets}signal_us_new2_g.png",
  "${pedestrianUSImageAssets}signal_us_old_g.png",
  "${pedestrianUKImageAssets}signal_uk_new_g.png",
  "${pedestrianUKImageAssets}signal_uk_old_g.png",
  "${pedestrianJPImageAssets}signal_jp_new_g.png",
  "${pedestrianJPImageAssets}signal_jp_old_g.png",
  "${pedestrianUKImageAssets}signal_uk_old_g.png"
];
//Flash
const List<String> pedestrianSignalFlashString = [
  "${pedestrianUSImageAssets}signal_us_new2_r.png",
  "${pedestrianUSImageAssets}signal_us_old_r.png",
  "${pedestrianUKImageAssets}signal_uk_new_g.png",
  "${pedestrianUKImageAssets}signal_uk_old_g.png",
  "${pedestrianJPImageAssets}signal_jp_new_g.png",
  "${pedestrianJPImageAssets}signal_jp_old_g.png",
  "${pedestrianUKImageAssets}signal_uk_old_g.png"
];
//Red
const List<String> pedestrianSignalRedString = [
  "${pedestrianUSImageAssets}signal_us_new2_r.png",
  "${pedestrianUSImageAssets}signal_us_old_r.png",
  "${pedestrianUKImageAssets}signal_uk_new_r.png",
  "${pedestrianUKImageAssets}signal_uk_old_r.png",
  "${pedestrianJPImageAssets}signal_jp_new_r.png",
  "${pedestrianJPImageAssets}signal_jp_old_r.png",
  "${pedestrianUKImageAssets}signal_uk_old_r.png"
];
//Off
const List<String> pedestrianSignalOffString = [
  "${pedestrianUSImageAssets}signal_us_new2_off.png",
  "${pedestrianUSImageAssets}signal_us_old_off.png",
  "${pedestrianUKImageAssets}signal_uk_new_off.png",
  "${pedestrianUKImageAssets}signal_uk_old_off.png",
  "${pedestrianJPImageAssets}signal_jp_new_off.png",
  "${pedestrianJPImageAssets}signal_jp_old_off.png",
  "${pedestrianUKImageAssets}signal_uk_old_off.png"
];
//Countdown Number
const List<double> cdNumTopSpaceRate = [0.07, 0, 0.189, 0, 0, 0, 0];
const List<double> cdNumLeftSpaceRate = [0.14, 0, 0.157, 0, 0, 0, 0];
const List<double> cdNumPaddingRate = [0.03, 0, 0.018, 0, 0, 0, 0];
const List<double> cdNumFontSizeRate = [0.115, 0, 0.055, 0, 0, 0, 0];
const List<Color> cdNumColor = [orangeColor, transpColor, yellowColor, transpColor, transpColor, transpColor, transpColor];
const List<String> cdNumFont = ["dotFont", "", "freeTfb", "", "", "", ""];
//Countdown Meter
const String jpCountDownOn = "${pedestrianJPImageAssets}countdown_jp_on.png";
const String jpCountDownOff = "${pedestrianJPImageAssets}countdown_jp_off.png";
const double countMeterTopSpaceRate =  0.035;
const double countMeterCenterSpaceRate =  0.08;
const double countDownRightPaddingRate = 0.003;
const double countMeterWidthRate =  0.012;
const double countMeterHeightRate =  0.01;
const double countMeterSpaceRate =  0.0024;

///Traffic Signal
//Green
const List<String> trafficSignalGreenString = [
  "${trafficUSImageAssets}signal_us_new_g.png",
  "${trafficUSImageAssets}signal_us_old_g.png",
  "${trafficUKImageAssets}signal_uk_new_g.png",
  "${trafficUKImageAssets}signal_uk_old_g.png",
  "${trafficJPImageAssets}signal_jp_new_g.png",
  "${trafficJPImageAssets}signal_jp_old_g.png",
  "${trafficAUImageAssets}signal_au_g.png"
];
//Yellow
const List<String> trafficSignalYellowString = [
  "${trafficUSImageAssets}signal_us_new_y.png",
  "${trafficUSImageAssets}signal_us_old_y.png",
  "${trafficUKImageAssets}signal_uk_new_y.png",
  "${trafficUKImageAssets}signal_uk_old_g.png",
  "${trafficJPImageAssets}signal_jp_new_y.png",
  "${trafficJPImageAssets}signal_jp_old_y.png",
  "${trafficAUImageAssets}signal_au_y.png"
];
//Red
const List<String> trafficSignalRedString = [
  "${trafficUSImageAssets}signal_us_new_r.png",
  "${trafficUSImageAssets}signal_us_old_r.png",
  "${trafficUKImageAssets}signal_uk_new_r.png",
  "${trafficUKImageAssets}signal_uk_old_r.png",
  "${trafficJPImageAssets}signal_jp_new_r.png",
  "${trafficJPImageAssets}signal_jp_old_r.png",
  "${trafficAUImageAssets}signal_au_r.png"
];
//Off
const List<String> trafficSignalOffString = [
  "${trafficUSImageAssets}signal_us_new_y.png",
  "${trafficUSImageAssets}signal_us_old_g.png",
  "${trafficUKImageAssets}signal_uk_new_y.png",
  "${trafficUKImageAssets}signal_uk_old_g.png",
  "${trafficJPImageAssets}signal_jp_new_y.png",
  "${trafficJPImageAssets}signal_jp_old_y.png",
  "${trafficAUImageAssets}signal_au_y.png"
];
//Off
const List<String> trafficSignalArrowString = [
  "${trafficUSImageAssets}signal_us_new_r.png",
  "${trafficUSImageAssets}signal_us_old_r.png",
  "${trafficUKImageAssets}signal_uk_new_r.png",
  "${trafficUKImageAssets}signal_uk_old_r.png",
  "${trafficJPImageAssets}signal_jp_new_arrow.png",
  "${trafficJPImageAssets}signal_jp_old_arrow.png",
  "${trafficAUImageAssets}signal_au_r.png"
];
//stop/go flag
const String usStopFlag = "${trafficUSImageAssets}stop_flag.png";
const String usGoFlag = "${trafficUSImageAssets}go_flag.png";
const double stopGoFlagHeightRate = 0.18;
const int flagRotationTime = 1;

/// Floating Action Button
const double floatingButtonSizeRate = 0.07;
const double floatingImageSizeRate = 0.02;
const double floatingIconSizeRate = 0.03;

///Upgrade
const String premiumProduct = "signal_upgrade_premium";
const double upgradeAppBarHeight = 45;
const double premiumTitleFontSizeRate = 0.035;
const double premiumPriceFontSizeRate = 0.08;
const double premiumPricePaddingRate = 0.025;
const double upgradeButtonFontSizeRate = 0.025;
const double upgradeTableFontSizeRate = 0.018;
const double upgradeTableIconSizeRate = 0.03;
const double upgradeTableHeadingHeightRate = 0.03;
const double upgradeTableHeightRate = 0.06;
const double upgradeButtonPaddingRate = 0.003;
const double upgradeButtonBottomMarginRate = 0.04;