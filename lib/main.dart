import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'extension.dart';
import 'firebase_options.dart';
import 'plan_provider.dart';
import 'constant.dart';
import 'homepage.dart';
import 'settings.dart';
import 'upgrade.dart';

final waitTimeProvider = StateProvider<int>((ref) => initialWaitTime);
final goTimeProvider = StateProvider<int>((ref) => initialGoTime);
final flashTimeProvider = StateProvider<int>((ref) => initialFlashTime);
final yellowTimeProvider = StateProvider<int>((ref) => initialYellowTime);
final arrowTimeProvider = StateProvider<int>((ref) => initialArrowTime);
final isSoundProvider = StateProvider<bool>((ref) => true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); //縦向き指定
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  )); // Status bar style
  await dotenv.load(fileName: 'assets/.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Settings.init(cacheProvider: SharePreferenceCache(),);
  final planNotifier = PlanNotifier();
  await planNotifier.initializePremiumStatus();
  final savedWaitTime = "wait".getSettingsValueInt(initialWaitTime);
  final savedGoTime = "go".getSettingsValueInt(initialGoTime);
  final savedFlashTime = "flash".getSettingsValueInt(initialFlashTime);
  final savedYellowTime = "yellow".getSettingsValueInt(initialYellowTime);
  final savedArrowTime = "arrow".getSettingsValueInt(initialArrowTime);
  final savedIsSound = "sound".getSettingsValueBool(true);
  runApp(ProviderScope(
    overrides: [
      waitTimeProvider.overrideWith((ref) => savedWaitTime),
      goTimeProvider.overrideWith((ref) => savedGoTime),
      flashTimeProvider.overrideWith((ref) => savedFlashTime),
      yellowTimeProvider.overrideWith((ref) => savedYellowTime),
      arrowTimeProvider.overrideWith((ref) => savedArrowTime),
      isSoundProvider.overrideWith((ref) => savedIsSound),
    ],
    child: MyApp())
  );

  // RevenueCat初期化
  final apiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ? "REVENUE_CAT_IOS_API_KEY": "REVENUE_CAT_ANDROID_API_KEY");
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(PurchasesConfiguration(apiKey));
  await Purchases.enableAdServicesAttributionTokenCollection();
  
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();
  
  // ATT
  await initATTPlugin();

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'LETS SIGNAL',
      theme: ThemeData(colorScheme: const ColorScheme.light(primary: greenColor)),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        '/h' : (_) => const HomePage(),
        '/s' : (_) => const SettingsPage(),
        '/u' : (_) => const UpgradePage(),
      },
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        RouteObserver<ModalRoute>()
      ],
    );
  }
}

///App Tracking Transparency
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
