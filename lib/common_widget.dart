import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'constant.dart';

Future<void> initPlugin(BuildContext context) async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final iosInfo = await deviceInfo.iosInfo;
  final iosOsVersion = iosInfo.systemVersion!;
  if (status == TrackingStatus.notDetermined) {
    if (double.parse(iosOsVersion) >= 15) {
      "iOS${double.parse(iosOsVersion)}".debugPrint();
      await showCupertinoDialog(context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(context.appTitle()),
            content: Text(context.thisApp()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        }
      );
    }
    await Future.delayed(const Duration(milliseconds: 200));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

///App Bar
Widget appTitleText(String lang, String title) =>
    Text(title,
      style: TextStyle(
        fontFamily: "beon",
        fontSize: (lang == "ja") ? jpTitleFontSize: usTitleFontSize,
        fontWeight: FontWeight.bold,
        color: whiteColor,
      ),
      textScaleFactor: 1.0,
    );

///Signal
//us
Widget usSignal(double height, bool isNew, bool isGreen, bool isFlash, bool opaque, int countDown) =>
    SizedBox(
      height: height * isNew.usSignalHeightRate(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(image: AssetImage(isGreen.usSignalImage(isFlash, isNew, opaque))),
          if (isNew) usCountDown(height, countDown, isFlash),
          if (isNew) const Image(image: AssetImage(netImage)),
        ],
      ),
    );
//uk
Widget ukSignal(double height, bool isNew, bool isGreen, bool isFlash, bool opaque, int countDown) =>
    SizedBox(
      height: height * isNew.ukSignalHeightRate(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(image: AssetImage(isGreen.ukSignalImage(isFlash, isNew, opaque, countDown))),
          if (isNew) ukCountDown(height, countDown, isFlash),
        ],
      ),
    );
//jp
Widget jpSignal(double height, bool isNew, bool isGreen, bool isFlash, bool opaque, int countDown, int goTime) =>
    SizedBox(
      height: height * isNew.jpSignalHeightRate(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(image: AssetImage(isGreen.jpSignalImage(isFlash, isNew, opaque))),
          if (isNew) jpCountDown(height, countDown, goTime),
        ],
      ),
    );

///Background
//common
Widget backGroundImage(double height, String countryCode) =>
    Column(children: [
      const Spacer(flex: 1),
      (countryCode == "JP") ? jpFlagImage(height): countryFlagImage(height, countryCode),
      const Spacer(flex: 1),
      (countryCode == "JP") ? jpFlagImage(height): countryFlagImage(height, countryCode),
      const Spacer(flex: 1),
      SizedBox(height: height.admobHeight())
    ]);

Widget countryFlagImage(double height, String countryCode) =>
    SizedBox(
      height: height / 3,
      child: Image.asset(countryCode.countryFlag()),
    );
//jp
Widget jpFlagImage(double height) =>
    Container(
      width: height / 3,
      height: height / 3,
      decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
    );

///Countdown
//us
Widget usCountDown(double height, int countDown, bool isFlash) =>
    Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: height * usCountDownTopSpaceRate),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: height * usCountDownLeftSpaceRate),
            usCountDownNumber(height, countDown, isFlash, true),
            usCountDownNumber(height, countDown, isFlash, false),
          ],
        ),
      ],
    );

Widget usCountDownNumber(double height, int countDown, bool isFlash, bool is10) =>
    Stack(children: [
      countDownNumberText(height, usCountDownFont, usCountDownFontSizeRate, "8", signalGrayColor),
      Padding(
        padding: EdgeInsets.only(
            left: height * countDown.countDownNumber(isFlash, is10).isOne() * usCountDownPaddingRate
        ),
        child: countDownNumberText(height, usCountDownFont, usCountDownFontSizeRate,
          "${countDown.countDownNumber(isFlash, is10)}",
          countDown.countDownColor(orangeColor, isFlash, is10),
        ),
      ),
    ]);

Text countDownNumberText(double height, String font, double fontSizeRate, String number, Color color) =>
    Text(number,
      style: TextStyle(
          color: color,
          fontFamily: font,
          fontSize: height * fontSizeRate,
          fontWeight: FontWeight.bold
      ),
    );
//uk
Widget ukCountDown(double height, int countDown, bool isFlash) =>
    Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: height * ukCountDownTopSpaceRate),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: height * ukCountDownLeftSpaceRate),
            ukCountDownNumber(height, countDown, isFlash, true),
            ukCountDownNumber(height, countDown, isFlash, false),
          ],
        ),
      ],
    );

Widget ukCountDownNumber(double height, int countDown, bool isFlash, bool is10) =>
    Stack(children: [
      countDownNumberText(height, ukCountDownFont, ukCountDownFontSizeRate, "8", signalGrayColor),
      Padding(
        padding: EdgeInsets.only(
            left: height * countDown.countDownNumber(isFlash, is10).isOne() * ukCountDownPaddingRate
        ),
        child: countDownNumberText(height, ukCountDownFont, ukCountDownFontSizeRate,
          "${countDown.countDownNumber(isFlash, is10)}",
          countDown.countDownColor(yellowColor, isFlash, is10),
        ),
      ),
    ]);
//jp
Widget jpCountDown(double height, int countDown, int goTime) =>
    Container(
      padding: EdgeInsets.only(right: height * jpCountDownRightPaddingRate),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: height * jpCountMeterTopSpaceRate),
            for(int i = 0; i < 8; i++) ... {
              Row(children: [
                const Spacer(),
                jpCountDownBar(height, countDown.jpCountMeterColor(goTime)[i]),
                SizedBox(width: height * jpCountMeterCenterSpaceRate),
                jpCountDownBar(height, countDown.jpCountMeterColor(goTime)[i]),
                const Spacer(),
              ]),
              SizedBox(height: height * jpCountMeterSpaceRate),
            },
          ]
      )
    );

Widget jpCountDownBar(double height, bool isOn) =>
    SizedBox(
        width: height * jpCountMeterWidthRate,
        height: height * jpCountMeterHeightRate,
        child: Image.asset(isOn ? jpCountDownOn: jpCountDownOff),
    );

///Push Button
//common
ButtonStyle pushButtonStyle() =>
    ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: MaterialStateProperty.all(transpColor),
      foregroundColor: MaterialStateProperty.all(transpColor),
      shadowColor: MaterialStateProperty.all(transpColor),
      backgroundColor: MaterialStateProperty.all(transpColor),
      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
    );

Widget pushButtonImage(double height, bool isNew, bool isPressed, String countryCode) =>
    (countryCode == "UK") ? ukPushButtonImage(height, isNew, isPressed):
    (countryCode == "JP") ? jpPushButtonImage(height, isNew):
    usPushButtonImage(height, isNew, isPressed);
//us
Widget usPushButtonImage(double height, bool isNew, bool isPressed) =>
    SizedBox(
      height: height * isNew.usButtonHeightRate(),
      child: Image(image: AssetImage(isNew.usButtonImage(isPressed)))
    );
//uk
Widget ukPushButtonImage(double height, bool isNew, bool isPressed) =>
    SizedBox(
      height: height * isNew.ukButtonHeightRate(),
      child: Image(image: AssetImage(isNew.ukButtonImage(isPressed)))
    );
//jp
Widget jpPushButtonImage(double height, bool isNew) =>
    SizedBox(
        height: height * isNew.jpButtonHeightRate(),
        child: Image(image: AssetImage(isNew.jpButtonImage()))
    );

///Frame
//common
Widget frameImage(double height, bool isNew, bool isGreen, bool isPressed, String countryCode) =>
    (countryCode == "UK") ? ukFrameImage(height, isNew, isGreen, isPressed):
    (countryCode == "JP") ? jpFrameImage(height, isNew, isGreen, isPressed):
    usFrameImage(height, isNew);

//us
Widget usFrameImage(double height, bool isNew) =>
    SizedBox(
      height: height * isNew.usFrameHeightRate(),
      child: Image(image: AssetImage(isNew.usFrameImage()))
    );
//uk
Widget ukFrameImage(double height, bool isNew, bool isGreen, bool isPressed) =>
    SizedBox(
      height: height * isNew.ukFrameHeightRate(),
      child: Image(image: AssetImage(isNew.ukFrameImage(isGreen, isPressed)))
    );
//jp
Widget jpFrameImage(double height, bool isNew, bool isGreen, bool isPressed) =>
    SizedBox(
      height: height * isNew.jpFrameHeightRate(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Image(image: AssetImage(isNew.jpFrameImage())),
          jpFrameLabels(height, isPressed, isGreen, isNew),
        ],
      ),
    );

Widget jpFrameLabels(double height, bool isPressed, bool isGreen, bool isNew) =>
    SizedBox(height: height * isNew.jpFrameHeightRate(),
      child: Stack(alignment: Alignment.center,
        children: [
          Column(children: [
            SizedBox(height: height * isNew.jpLabelTopMarginRate()),
            jpFrameLabel(height, isGreen, isPressed, isNew, true),
            SizedBox(height: height * isNew.jpLabelMiddleMarginRate()),
            jpFrameLabel(height, isGreen, isPressed, isNew, false),
          ]),
        ],
      ),
    );

Widget jpFrameLabel(double height, bool isGreen, bool isPressed, bool isNew, bool isUpper) =>
    Container(
      alignment: Alignment.center,
      height: height * jpLabelHeightRate,
      width: height * jpLabelWidthRate,
      color: blackColor,
      child: Text(isPressed.jpFrameMessage(isGreen, isNew, isUpper),
        style: TextStyle(
          color: isNew ? whiteColor: redColor,
          fontSize: height * jpLabelFontSizeRate,
          fontWeight: FontWeight.bold,
        ),
        textScaleFactor: 1.0,
      ),
    );

///Floating Button
Widget selectCountryFlag(String lang, String nextCountry, double size) =>
    Container(width: 1.5 * size, height: size, color: whiteColor,
      padding: (nextCountry == "JP") ? EdgeInsets.all(size.jpFlagPadding()): null,
      child: Stack(children: [
        (nextCountry == "JP") ? jpFlagImage(100): Image.asset(nextCountry.countryFlag()),
        Container(
          alignment: Alignment.center,
          child: Text("▶︎",
            style: TextStyle(
              fontSize: 0.6 * size,
              fontWeight: FontWeight.bold,
              color: whiteColor,
              backgroundColor: (nextCountry == "JP") ? transpColor: transpBlackColor,
            ),
          ),
        ),
      ]),
    );

Widget selectOldOrNew(BuildContext context, String countryCode, bool isNew, double fontSize) =>
    Text(context.oldOrNew(isNew),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );

///Admob
Widget adMobBannerWidget(double width, double height, BannerAd myBanner) =>
    Container(
      width: width.admobWidth(),
      height: height.admobHeight(),
      color: whiteColor,
      child: AdWidget(ad: myBanner),
    );


