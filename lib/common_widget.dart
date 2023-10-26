import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'common_extension.dart';
import 'constant.dart';

///App Tracking Transparency
Future<void> initPlugin(BuildContext context) async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined && context.mounted) {
      await showCupertinoDialog(context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(context.appTitle()),
            content: Text(context.thisApp()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        }
      );
    // }
    await Future.delayed(const Duration(milliseconds: 200));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

///App Bar
PreferredSize myHomeAppBar(BuildContext context, int counter) =>
    PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight),
      child: AppBar(
        title: titleText(context, context.appTitle()),
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

Widget upgradeAppBar(BuildContext context, bool isPremium, isPurchase) =>
    Container(
      height: upgradeAppBarHeight + context.topPadding(),
      padding: EdgeInsets.only(top: context.topPadding() - 10),
      color: signalGrayColor,
      child: Stack(alignment: Alignment.center,
        children: [
          Row(children: [
            const SizedBox(width: 15),
            if (!isPurchase) IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: whiteColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
          ]),
          titleText(context, (isPremium) ? context.restore(): context.upgrade()),
        ],
      ),
    );

Widget titleText(BuildContext context, String title) =>
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

/// Pedestrian Signal Image
Widget pedestrianSignalImage(BuildContext context, int counter, countDown, greenTime, bool isGreen, isFlash, opaque) =>
    Container(
      height: context.height() * signalHeightRate,
      padding: EdgeInsets.all(context.height() * pedestrianSignalPaddingRate[counter]),
      child: Stack(alignment: Alignment.center,
        children: [
          Image(image: AssetImage(counter.pedestrianSignalImageString(isGreen, isFlash, opaque))),
          if (counter == 2) countDownNumber(context, counter, countDown, isFlash),
          if (counter == 4) jpNewCountDown(context, countDown, greenTime),
        ],
      ),
    );

//Countdown Number
Widget countDownNumber(BuildContext context, int counter, int countDown, bool isFlash) =>
    Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: context.height() * cdNumTopSpaceRate[counter]),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: context.height() * cdNumLeftSpaceRate[counter]),
            //Countdown number for the 10 place
            Stack(children: [
              //Background Number
              countDownText(context, counter, "8", signalGrayColor),
              //Count Down Number
              Container(
                padding: EdgeInsets.only(left: context.height() * countDown.cdTenLeftPaddingRate(counter, isFlash)),
                child: countDownText(context, counter, countDown.cdTenNumberString(isFlash), countDown.cdTenColor(cdNumColor[counter], isFlash)),
              ),
            ]),
            //Countdown number for the first place
            Stack(children: [
              //Background Number
              countDownText(context, counter, "8", signalGrayColor),
              //Count Down Number
              Container(
                padding: EdgeInsets.only(left: context.height() * countDown.cdFirstLeftPaddingRate(counter, isFlash)),
                child: countDownText(context, counter, countDown.cdFirstNumberString(isFlash), countDown.cdFirstColor(cdNumColor[counter], isFlash)),
              ),
            ]),
          ],
        ),
      ],
    );

//Countdown Text
Text countDownText(BuildContext context, int counter, String text, Color color) =>
    Text(text,
      style: TextStyle(
        color: color,
        fontFamily: cdNumFont[counter],
        fontSize: context.height() * cdNumFontSizeRate[counter],
        fontWeight: FontWeight.bold
      )
    );

// Countdown for Jp New Pedestrian Signal
Widget jpNewCountDown(BuildContext context, int countDown, int greenTime) =>
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
              SizedBox(
                width: context.height() * countMeterWidthRate,
                height: context.height() * countMeterHeightRate,
                child: Image.asset(countDown.countMeterColor(greenTime)[i] ? jpCountDownOn: jpCountDownOff),
              ),
              SizedBox(width: context.height() * countMeterCenterSpaceRate),
              SizedBox(
                width: context.height() * countMeterWidthRate,
                height: context.height() * countMeterHeightRate,
                child: Image.asset(countDown.countMeterColor(greenTime)[i] ? jpCountDownOn: jpCountDownOff),
              ),
              const Spacer(),
            ]),
            SizedBox(height: context.height() * countMeterSpaceRate),
          },
        ]
      )
    );

/// Traffic Signal Image
Widget trafficSignalImage(BuildContext context, int counter, greenTime, bool isGreen, isYellow, isArrow, opaque) =>
    SizedBox(
      height: context.height() * signalHeightRate,
      child: Container(
        padding: EdgeInsets.all(context.height() * trafficSignalPaddingRate[counter]),
        child: Stack(alignment: Alignment.center,
          children: [
            if (counter == 1) usOldSignal(context, isGreen, true),
            if (counter == 1) usOldSignal(context, isGreen, false),
            Image(image: AssetImage(counter.trafficSignalImageString(isGreen, isYellow, isArrow, opaque))),
          ],
        ),
      ),
    );

// US Old Traffic Signal
Widget usOldSignal(BuildContext context, bool isGreen, isGo) =>
  AnimatedContainer(
    height: context.height() * stopGoFlagHeightRate,
    transform: Matrix4.rotationZ(((isGreen && !isGo) || (!isGreen && isGo)) ? 1.57: 0),
    duration: const Duration(seconds: flagRotationTime),
    child: Image(image: AssetImage(isGo ? usGoFlag: usStopFlag)),
  );

///Push Button
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

//Push Button Image
Widget pushButtonImage(BuildContext context, int counter, bool isGreen, isPressed) =>
    Container(
      height: context.height() * buttonHeightRate[counter],
      margin: EdgeInsets.only(top: context.height() * buttonTopMarginRate[counter]),
      child: Image(image: AssetImage(counter.pushButtonImageString(isGreen, isPressed)))
    );

// Push Button Japanese Frame label
Widget jpFrameLabel(BuildContext context, int counter, bool isPressed, isGreen) =>
    Column(children: [
      Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(top: context.height() * labelTopMarginRate[counter]),
        height: context.height() * labelHeightRate[counter],
        width: context.height() * labelWidthRate[counter],
        color: blackColor,
        child: Text(counter.jpFrameMessage(isPressed, isGreen, true),
          style: TextStyle(
            color: (counter == 4) ? whiteColor: redColor,
            fontSize: context.height() * labelFontSizeRate[counter],
            fontWeight: FontWeight.bold,
          ),
          textScaleFactor: 1.0,
        ),
      ),
      Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(top: context.height() * labelMiddleMarginRate[counter]),
        height: context.height() * labelHeightRate[counter],
        width: context.height() * labelWidthRate[counter],
        color: blackColor,
        child: Text(counter.jpFrameMessage(isPressed, isGreen, false),
          style: TextStyle(
            color: (counter == 4) ? whiteColor: redColor,
            fontSize: context.height() * labelFontSizeRate[counter],
            fontWeight: FontWeight.bold,
          ),
          textScaleFactor: 1.0,
        ),
      ),
    ]);

///Settings
AppBar settingsAppBar(BuildContext context, String title, bool isPurchase) =>
    AppBar(
      title: titleText(context, title),
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: signalGrayColor,
      foregroundColor: whiteColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () async => (isPurchase) ? null: context.pushHomePage(),
      ),
    );

Widget settingsTitle(BuildContext context, String title, int time) =>
    Row(children: [
      const Icon(Icons.watch_later_outlined, color: grayColor),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(color: blackColor)),
      const Spacer(),
      Text("$time${context.timeUnit()} ", style: const TextStyle(color: blackColor)),
    ]);

sliderTheme(BuildContext context, Color activeColor) =>
    SliderTheme.of(context).copyWith(
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      thumbColor: activeColor,
      valueIndicatorColor: activeColor,
      overlayColor: activeColor.withAlpha(80),
      activeTrackColor: activeColor,
      inactiveTrackColor: transpGrayColor,
      activeTickMarkColor: activeColor,
      inactiveTickMarkColor: grayColor,
    );

EdgeInsets settingsTitlePadding(bool isBottom) =>
    EdgeInsets.only(
      top: settingsTilePaddingSize,
      bottom: isBottom ? settingsTilePaddingSize / 2: 0,
      left: settingsTilePaddingSize,
      right: settingsTilePaddingSize,
    );

BoxDecoration settingsTileDecoration(bool isTop, isBottom) =>
    BoxDecoration(
      color: (Platform.isIOS || Platform.isMacOS) ? whiteColor: transpColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isTop ? settingsTileRadiusSize: 0),
        topRight: Radius.circular(isTop ? settingsTileRadiusSize: 0),
        bottomLeft: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
        bottomRight: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
      ),
    );

///Upgrade
Text premiumTitle(BuildContext context) =>
    Text(context.premiumPlan(),
      style: upgradeTextStyle(context, premiumTitleFontSizeRate, signalGrayColor),
    );

Widget upgradePrice(BuildContext context, String price, bool isPremium) =>
    Container(
      padding: EdgeInsets.all(context.height() * premiumPricePaddingRate),
      child: (!isPremium) ? Text(price,
        style: upgradeTextStyle(context, premiumPriceFontSizeRate, yellowColor),
      ): null,
    );

Widget upgradeButtonImage(BuildContext context, bool isRestore) =>
    Material(
      elevation: upgradeButtonElevation,
      child: Container(
        padding: EdgeInsets.all(context.height() * upgradeButtonPaddingRate),
        decoration: BoxDecoration(
          color: isRestore ? greenColor: yellowColor,
          border: Border.all(color: signalGrayColor, width: upgradeButtonBorderWidth),
          borderRadius: BorderRadius.circular(upgradeButtonBorderRadius),
        ),
        child: Text(isRestore ? context.toRestore(): context.toUpgrade(),
          style: upgradeTextStyle(context, upgradeButtonFontSizeRate, isRestore ? whiteColor: signalGrayColor),
        )
      )
    );

DataTable upgradeDataTable(BuildContext context) =>
    DataTable(
      headingRowHeight: context.height() * upgradeTableHeadingHeightRate,
      headingRowColor: MaterialStateColor.resolveWith((states) => signalGrayColor),
      headingTextStyle: const TextStyle(color: whiteColor),
      dividerThickness: upgradeTableDividerWidth,
      dataRowMaxHeight: context.height() * upgradeTableHeightRate,
      dataRowMinHeight: context.height() * upgradeTableHeightRate,
      columns: [
        dataColumnLabel(context, context.plan()),
        dataColumnLabel(context, context.free()),
        dataColumnLabel(context, context.premium()),
      ],
      rows: [
        tableDataRow(context, context.pushButton(), whiteColor, false),
        tableDataRow(context, context.pedestrianSignal(), transpGrayColor, false),
        tableDataRow(context, context.carSignal(), whiteColor, true),
        tableDataRow(context, context.noAds(), transpGrayColor, true),
      ],
    );

DataColumn dataColumnLabel(BuildContext context, String text) =>
    DataColumn(
      label: Expanded(
        child: Text(text,
          style: upgradeTextStyle(context, upgradeTableFontSizeRate, whiteColor),
          textAlign: TextAlign.center,
        ),
      ),
    );

DataRow tableDataRow(BuildContext context, String title, Color color, bool isPremium) =>
    DataRow(
      color: MaterialStateColor.resolveWith((states) => color),
      cells: [
        DataCell(Text(title,
          style: upgradeTextStyle(context, upgradeTableFontSizeRate, signalGrayColor),
          textAlign: TextAlign.left,
        )),
        isPremium ?
          iconDataCell(context, Icons.not_interested, redColor):
          iconDataCell(context, Icons.check_circle, greenColor),
        iconDataCell(context, Icons.check_circle, greenColor),
      ]
    );

TextStyle upgradeTextStyle(BuildContext context, double fontSizeRate, Color color) =>
    TextStyle(
        fontSize: context.height() * fontSizeRate,
        fontWeight: FontWeight.bold,
        fontFamily: "beon",
        color: color,
        decoration: TextDecoration.none
    );

DataCell iconDataCell(BuildContext context, IconData icon, Color color) =>
    DataCell(Center(child:
      Icon(icon, color: color, size: context.height() * upgradeTableIconSizeRate))
    );

Widget circularProgressIndicator(BuildContext context) =>
    Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: greenColor),
        SizedBox(height: context.height() * upgradeCircularProgressMarginBottomRate),
      ]
    );