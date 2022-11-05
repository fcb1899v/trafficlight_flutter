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
PreferredSize myHomeAppBar(BuildContext context, int counter) =>
    PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight),
      child: AppBar(
        title: titleText(context, counter, context.appTitle()),
        backgroundColor: signalGrayColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: whiteColor, size: 32),
            onPressed: () => context.pushSettingsPage(),
          ),
        ],
      ),
    );

Widget upgradeAppBar(BuildContext context, int counter) =>
    Container(
      height: upgradeAppBarHeight + context.topPadding(),
      padding: EdgeInsets.only(top: context.topPadding() - 10),
      color: signalGrayColor,
      child: Stack(alignment: Alignment.center,
        children: [
          Row(children: [
            const SizedBox(width: 15),
            GestureDetector(
              child: const Icon(Icons.arrow_back_ios, color: whiteColor),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            ),
            const Spacer(),
          ]),
          titleText(context, counter, context.upgrade()),
        ],
      ),
    );

Widget titleText(BuildContext context, int counter, String title) =>
    Text(title,
      style: const TextStyle(
        fontFamily: "beon",
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: whiteColor,
        decoration: TextDecoration.none
      ),
      textScaleFactor: 1.0,
    );


///Background
//common
Widget backGroundImage(BuildContext context, double height, int counter) =>
    Column(children: [
      const Spacer(flex: 1),
      countryFlagImage(height, counter),
      const Spacer(flex: 1),
      countryFlagImage(height, counter),
      const Spacer(flex: 1),
      SizedBox(height: context.admobHeight())
    ]);

Widget countryFlagImage(double height, int counter) =>
    (counter == 4 || counter == 5) ? Container(
      width: height / 3,
      height: height / 3,
      decoration: const BoxDecoration(color: redColor, shape: BoxShape.circle),
    ): SizedBox(
      height: height / 3,
      child: Image.asset(countryFlag[counter]),
    );

/// Signal Image
Widget signalImage(BuildContext context, int counter, countDown, greenTime, bool isGreen, isFlash, opaque, isPedestrian, isYellow, isArrow) =>
    SizedBox(height: context.height() * signalHeightRate,
      child: isPedestrian ?
        pedestrianSignalImage(context, counter, countDown, greenTime, isGreen, isFlash, opaque):
        trafficSignalImage(context, counter, isGreen, opaque, isYellow, isArrow),
    );

Widget pedestrianSignalImage(BuildContext context, int counter, countDown, greenTime, bool isGreen, isFlash, opaque) =>
    Container(
      padding: EdgeInsets.all(context.height() * pedestrianSignalPaddingRate[counter]),
      child: Stack(alignment: Alignment.center,
        children: [
          Image(image: AssetImage(counter.pedestrianSignalImageString(isGreen, isFlash, opaque))),
          if (counter == 2) countDownNumberWidget(context, counter, countDown, isFlash),
          if (counter == 4) jpCountDown(context, countDown, greenTime),
        ],
      )
    );

Widget trafficSignalImage(BuildContext context, int counter, bool isGreen, opaque, isYellow, isArrow) =>
    Container(
      padding: EdgeInsets.all(context.height() * trafficSignalPaddingRate[counter]),
      child: Stack(alignment: Alignment.center,
        children: [
          if (counter == 1) stopGoFlag(context, isGreen, true),
          if (counter == 1) stopGoFlag(context, isGreen, false),
          Image(image: AssetImage(counter.trafficSignalImageString(isGreen, isYellow, isArrow, opaque))),
        ],
      ),
    );


Widget stopGoFlag(BuildContext context, bool isGreen, isGo) =>
  AnimatedContainer(
    height: context.height() * stopGoFlagHeightRate,
    transform: Matrix4.rotationZ(((isGreen && !isGo) || (!isGreen && isGo)) ? 1.57: 0),
    duration: const Duration(seconds: flagRotationTime),
    child: Image(image: AssetImage(isGo ? usGoFlag: usStopFlag)),
  );

///Countdown Number
Widget countDownNumberWidget(BuildContext context, int counter, countDown, bool isFlash) =>
    Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: context.height() * cdNumTopSpaceRate[counter]),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: context.height() * cdNumLeftSpaceRate[counter]),
            countDownNumber(context, counter, countDown, isFlash, true),
            countDownNumber(context, counter, countDown, isFlash, false),
          ],
        ),
      ],
    );

Widget countDownNumber(BuildContext context, int counter, int countDown, bool isFlash, is10) =>
    Stack(children: [
      countDownNumberText(context, counter, "8", signalGrayColor),
      Container(
        padding: EdgeInsets.only(
          left: context.height() * countDown.cdNumber(isFlash, is10).isOne() * cdNumPaddingRate[counter]
        ),
        child: countDownNumberText(context, counter,
          "${countDown.cdNumber(isFlash, is10)}",
          countDown.cdNumColor(cdNumColor[counter], isFlash, is10),
        ),
      ),
    ]);

Text countDownNumberText(BuildContext context, int counter, String number, Color color) =>
    Text(number,
      style: TextStyle(
        color: color,
        fontFamily: cdNumFont[counter],
        fontSize: context.height() * cdNumFontSizeRate[counter],
        fontWeight: FontWeight.bold
      ),
    );

Widget jpCountDown(BuildContext context, int countDown, int greenTime) =>
    Container(
      padding: EdgeInsets.only(right: context.height() * countDownRightPaddingRate),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: context.height() * countMeterTopSpaceRate),
          for(int i = 0; i < 8; i++) ... {
            Row(children: [
              const Spacer(),
              jpCountDownBar(context, countDown.countMeterColor(greenTime)[i]),
              SizedBox(width: context.height() * countMeterCenterSpaceRate),
              jpCountDownBar(context, countDown.countMeterColor(greenTime)[i]),
              const Spacer(),
            ]),
            SizedBox(height: context.height() * countMeterSpaceRate),
          },
        ]
      )
    );

Widget jpCountDownBar(BuildContext context, bool isOn) =>
    SizedBox(
      width: context.height() * countMeterWidthRate,
      height: context.height() * countMeterHeightRate,
       child: Image.asset(isOn ? jpCountDownOn: jpCountDownOff),
    );

///Push Button
ButtonStyle pushButtonStyle() =>
    ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: MaterialStateProperty.all(transpColor),
      foregroundColor: MaterialStateProperty.all(transpColor),
      shadowColor: MaterialStateProperty.all(transpColor),
      backgroundColor: MaterialStateProperty.all(transpColor),
      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
    );

// Push Button Frame
Widget pushButtonFrame(BuildContext context, int counter, bool isGreen, isFlash, opaque, isPressed) =>
    Container(
      height: context.height() * frameHeightRate,
      padding: EdgeInsets.only(
        top: context.height() * frameTopPaddingRate[counter],
        bottom: context.height() * frameBottomPaddingRate[counter]
      ),
      child: Image(image: AssetImage(counter.buttonFrameImageString(isGreen, isFlash, opaque, isPressed)))
    );

// Push Button Frame label
Widget frameLabels(BuildContext context, int counter, bool isPressed, isGreen) =>
    Column(children: [
      SizedBox(height: context.height() * labelTopMarginRate[counter]),
      jpFrameLabel(context, counter, isPressed, isGreen, true),
      SizedBox(height: context.height() * labelMiddleMarginRate[counter]),
      jpFrameLabel(context, counter, isPressed, isGreen, false),
    ]);

Widget jpFrameLabel(BuildContext context, int counter, bool isPressed, isGreen, isUpper) =>
    Container(
      alignment: Alignment.center,
      height: context.height() * labelHeightRate[counter],
      width: context.height() * labelWidthRate[counter],
      color: blackColor,
      child: Text(counter.jpFrameMessage(isPressed, isGreen, isUpper),
        style: TextStyle(
          color: (counter == 4) ? whiteColor: redColor,
          fontSize: context.height() * labelFontSizeRate[counter],
          fontWeight: FontWeight.bold,
        ),
        textScaleFactor: 1.0,
      ),
    );

///Upgrade
Widget premiumTitle(BuildContext context) =>
    SizedBox(
      child: Text(context.premiumPlan(),
        style: TextStyle(
          fontSize: context.height() * premiumTitleFontSizeRate,
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: signalGrayColor,
          decoration: TextDecoration.none
        ),
      ),
    );

Widget upgradePrice(BuildContext context, String price) =>
    Container(
      padding: EdgeInsets.all(context.height() * premiumPricePaddingRate),
      child: Text(price,
        style: TextStyle(
          fontSize: context.height() * premiumPriceFontSizeRate,
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: amberColor,
          decoration: TextDecoration.none
        ),
      ),
    );

Widget upgradeButtonText(BuildContext context) =>
    Container(
      padding: EdgeInsets.all(context.height() * upgradeButtonPaddingRate),
      child: Text(context.upgrade(),
        style: TextStyle(
          fontSize: context.height() * upgradeButtonFontSizeRate,
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: signalGrayColor,
          decoration: TextDecoration.none
        )
      )
    );

DataTable upgradeDataTable(BuildContext context) =>
    DataTable(
      headingRowHeight: context.height() * upgradeTableHeadingHeightRate,
      headingRowColor: MaterialStateColor.resolveWith((states) => signalGrayColor),
      headingTextStyle: const TextStyle(color: whiteColor),
      dividerThickness: 0,
      dataRowHeight: context.height() * upgradeTableHeightRate,
      columns: [
        dataColumnLabel(context, context.plan()),
        dataColumnLabel(context, context.free()),
        dataColumnLabel(context, context.premium()),
      ],
      rows: [
        tableDataRow(context, context.pushButton(), false),
        tableDataRow(context, context.pedestrianSignal(), false),
        tableDataRow(context, context.carSignal(), true),
        tableDataRow(context, context.noAds(), true),
      ],
    );

DataColumn dataColumnLabel(BuildContext context, String text) =>
    DataColumn(
      label: Expanded(
        child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: "beon",
            color: whiteColor,
            fontSize: context.height() * upgradeTableFontSizeRate,
          ),
        ),
      ),
    );

DataRow tableDataRow(BuildContext context, String title, bool isPremium) =>
    DataRow(cells: [
      DataCell(Text(title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: signalGrayColor,
          fontSize: context.height() * upgradeTableFontSizeRate,
        ),
      )),
      isPremium ? iconDataCell(context, Icons.not_interested, redColor):
        iconDataCell(context, Icons.check_circle, greenColor),
      iconDataCell(context, Icons.check_circle, greenColor),
    ]);

DataCell iconDataCell(BuildContext context, IconData icon, Color color) =>
    DataCell(Center(child:
      Icon(icon, color: color, size: context.height() * upgradeTableIconSizeRate))
    );

///Admob
Widget adMobBannerWidget(BuildContext context, BannerAd myBanner, bool isNoAds) =>
    Container(
      width: context.admobWidth(),
      height: context.admobHeight(),
      color: transpColor,
      child: (isNoAds) ? null: AdWidget(ad: myBanner),
    );


