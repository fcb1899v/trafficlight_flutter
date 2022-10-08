import 'package:flutter/material.dart';

//アプリ名
const String appTitle = "LETS SIGNAL";
const String appTitleImage = "assets/images/letsSignal.png";

//言語ごとの初期設定
const List<String> usList = ["US", "UK", "JP"];
const List<String> ukList = ["UK", "US", "JP"];
const List<String> jpList = ["JP", "US", "UK"];

// 信号の時間
const int waitTime_0 = 4;     //seconds
const int goTime_0 = 8;       //seconds
const int flashTime_0 = 8;    //seconds
const int deltaFlash = 500;   //milliseconds

// Vibration
const int vibTime = 200;
const int vibAmp = 128;

//Title Font Size
const double usTitleFontSize = 32;
const double jpTitleFontSize = 24;

// String
const String wait = "wait";

// Sound File
const String buttonSound = "audios/pon.mp3";
const String noneSound = "${audioFile}none.mp3";
const String audioFile = "audios/sound_";
const String usSoundNewG = "${audioFile}us_g.mp3";
const String usSoundNewR = "${audioFile}us_r.mp3";
const String usSoundOldG = "${audioFile}none.mp3";
const String usSoundOldR = "${audioFile}none.mp3";
const String ukSoundNewG = "${audioFile}uk_g.mp3";
const String ukSoundNewR = "${audioFile}none.mp3";
const String ukSoundOldG = "${audioFile}none.mp3";
const String ukSoundOldR = "${audioFile}none.mp3";
const String jpSoundNewG = "${audioFile}jp_new.mp3";
const String jpSoundNewR = "${audioFile}none.mp3";
const String jpSoundOldG = "${audioFile}jp_old.mp3";
const String jpSoundOldR = "${audioFile}none.mp3";

// Sound Volume
const double musicVolume = 1;
const double buttonVolume = 0.5;

//Pedestrian Image File (us)
const String usImageAssets = "assets/images/pedestrian/us/";
const String usFlag = "${usImageAssets}flag_us.png";
const String usNewFrame = "${usImageAssets}frame_us_new.png";
const String usOldFrame = "${usImageAssets}frame_us_old.png";
const String usNewButtonOn = "${usImageAssets}button_us_new_on.png";
const String usNewButtonOff = "${usImageAssets}button_us_new_off.png";
const String usOldButton = "${usImageAssets}button_us_old.png";
const String usNewSignalG = "${usImageAssets}signal_us_new_g.png";
const String usNewSignalR = "${usImageAssets}signal_us_new_r.png";
const String usNewSignalOff = "${usImageAssets}signal_us_new_off.png";
const String usOldSignalG = "${usImageAssets}signal_us_old_g.png";
const String usOldSignalR = "${usImageAssets}signal_us_old_r.png";
const String usOldSignalOff = "${usImageAssets}signal_us_old_off.png";
const String netImage = "${usImageAssets}net.png";

//Pedestrian Image File (uk)
const String ukImageAssets = "assets/images/pedestrian/uk/";
const String ukFlag = "${ukImageAssets}flag_uk.png";
const String ukNewFrameOff = "${ukImageAssets}frame_uk_new_off.png";
const String ukNewFrameG = "${ukImageAssets}frame_uk_new_g.png";
const String ukNewFrameR = "${ukImageAssets}frame_uk_new_r.png";
const String ukOldFrameOff = "${ukImageAssets}frame_uk_old_off.png";
const String ukOldFrameOn = "${ukImageAssets}frame_uk_old_on.png";
const String ukNewButtonOn = "${ukImageAssets}button_uk_new_on.png";
const String ukNewButtonOff = "${ukImageAssets}button_uk_new_off.png";
const String ukOldButton = "${ukImageAssets}button_uk_old.png";
const String ukNewSignalG = "${ukImageAssets}signal_uk_new_g.png";
const String ukNewSignalR = "${ukImageAssets}signal_uk_new_r.png";
const String ukNewSignalOff = "${ukImageAssets}signal_uk_new_off.png";
const String ukOldSignalG = "${ukImageAssets}signal_uk_old_g.png";
const String ukOldSignalR = "${ukImageAssets}signal_uk_old_r.png";
const String ukOldSignalOff = "${ukImageAssets}signal_uk_old_off.png";

//Pedestrian Image File (jp)
const String jpImageAssets = "assets/images/pedestrian/jp/";
const String jpFlag = "${jpImageAssets}flag_jp.png";
const String jpNewFrame = "${jpImageAssets}frame_jp_new.png";
const String jpOldFrame = "${jpImageAssets}frame_jp_old.png";
const String jpNewButton = "${jpImageAssets}button_jp_new.png";
const String jpOldButton = "${jpImageAssets}button_jp_old.png";
const String jpNewSignalG = "${jpImageAssets}signal_jp_new_g.png";
const String jpNewSignalR = "${jpImageAssets}signal_jp_new_r.png";
const String jpNewSignalOff = "${jpImageAssets}signal_jp_new_off.png";
const String jpOldSignalG = "${jpImageAssets}signal_jp_old_g.png";
const String jpOldSignalR = "${jpImageAssets}signal_jp_old_r.png";
const String jpOldSignalOff = "${jpImageAssets}signal_jp_old_off.png";
const String jpCountDownOn = "${jpImageAssets}countdown_jp_on.png";
const String jpCountDownOff = "${jpImageAssets}countdown_jp_off.png";

//Pedestrian Image File (au)
const String auImageAssets = "assets/images/pedestrian/au/";
const String auFlag = "${auImageAssets}flag_au.png";
const String auButton = "${jpImageAssets}button_au.png";
const String auFrameOff = "${auImageAssets}frame_au_off.png";
const String auFrameOn = "${auImageAssets}frame_au_on.png";

//Floating Button Image
const String whiteArrow = "assets/images/whiteArrow.png";


//Signal Height Rate
const double jpNewSignalHeightRate =  0.35;
const double jpOldSignalHeightRate =  0.35;
const double usNewSignalHeightRate =  0.30;
const double usOldSignalHeightRate =  0.23;
const double ukNewSignalHeightRate =  0.27;
const double ukOldSignalHeightRate =  0.27;
const double auSignalHeightRate =  0.27;


//Button Total Height Rate
const double jpNewButtonTotalHeightRate =  0.35;
const double jpOldButtonTotalHeightRate =  0.35;
const double usNewButtonTotalHeightRate =  0.45;
const double usOldButtonTotalHeightRate =  0.44;
const double ukNewButtonTotalHeightRate =  0.43;
const double ukOldButtonTotalHeightRate =  0.43;
const double auButtonTotalHeightRate =  0.43;

//Frame Height Rate
const double jpNewFrameHeightRate =  0.35;
const double jpOldFrameHeightRate =  0.35;
const double usNewFrameHeightRate =  0.45;
const double usOldFrameHeightRate =  0.35;
const double ukNewFrameHeightRate =  0.43;
const double ukOldFrameHeightRate =  0.43;
const double auFrameHeightRate =  0.43;

//Button Height Rate
const double jpNewButtonHeightRate = 0.112;
const double jpOldButtonHeightRate = 0.100;
const double usNewButtonHeightRate = 0.150;
const double usOldButtonHeightRate = 0.120;
const double ukNewButtonHeightRate = 0.055;
const double ukOldButtonHeightRate = 0.050;
const double auButtonHeightRate = 0.050;


//Button Top Space Rate
const double jpNewButtonTopMarginRate = 0.122;
const double jpOldButtonTopMarginRate = 0.13;
const double usNewButtonTopMarginRate = 0.25;
const double usOldButtonTopMarginRate = 0.317;
const double ukNewButtonTopMarginRate = 0.352;
const double ukOldButtonTopMarginRate = 0.346;
const double auButtonTopMarginRate = 0.346;


//Label (jp)
const double jpNewLabelTopMarginRate = 0.060;
const double jpOldLabelTopMarginRate = 0.070;
const double jpNewLabelMiddleMarginRate = 0.165;
const double jpOldLabelMiddleMarginRate = 0.153;
const double jpLabelHeightRate =  0.035;
const double jpLabelWidthRate =  0.16;
const double jpLabelFontSizeRate = 0.02;

//Countdown (jp)
const double jpCountMeterTopSpaceRate =  0.04;
const double jpCountMeterCenterSpaceRate =  0.09;
const double jpCountDownRightPaddingRate = 0.003;
const double jpCountMeterWidthRate =  0.014;
const double jpCountMeterHeightRate =  0.0105;
const double jpCountMeterSpaceRate =  0.003;

//Countdown (us & uk)
const double usCountDownTopSpaceRate =  0.095;
const double ukCountDownTopSpaceRate =  0.173;
const double usCountDownLeftSpaceRate =  0.12;
const double ukCountDownLeftSpaceRate =  0.15;
const double usCountDownFontSizeRate =  0.1;
const double ukCountDownFontSizeRate =  0.055;
const double usCountDownPaddingRate = 0.03;
const double ukCountDownPaddingRate = 0.018;
const String usCountDownFont = "freeTfb";
const String ukCountDownFont = "freeTfb";

// Color
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;
const Color signalGrayColor = Color.fromRGBO(35, 35, 35, 1);    //#232323
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.8);
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.9);
const Color edgeColor1 = Color.fromRGBO(180, 180, 180, 1);      //#b4b4b4
const Color edgeColor2 = Color.fromRGBO(230, 230, 230, 1);      //#e6e6e6
const Color yellowColor = Color.fromRGBO(250, 210, 90, 1);      //#fad25a
const Color darkYellowColor = Color.fromRGBO(190, 140, 60, 1);  //#be8c3c
const Color orangeColor = Color.fromRGBO(209, 130, 64, 1);      //#d18240
const Color greenColor = Color.fromRGBO(87, 191, 163, 1);       //#57BFA3
const Color redColor = Color.fromRGBO(200, 77, 62, 1);          //#C84D3E

