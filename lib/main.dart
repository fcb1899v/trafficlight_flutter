import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_function.dart';
import 'constant.dart';
import 'firebase_options.dart';
import 'my_homepage.dart';
import 'settings.dart';
import 'upgrade.dart';

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
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();
  await initATTPlugin();
  initSettings().then((_) => runApp(const ProviderScope(child: MyApp())));
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
      home: const MyHomePage(),
      routes: {
        '/h' : (_) => const MyHomePage(),
        '/s' : (_) => const MySettingsPage(),
        '/u' : (_) => const MyUpgradePage(),
      },
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        RouteObserver<ModalRoute>()
      ],
    );
  }
}

Future<void> initSettings() async {
  await Settings.init(cacheProvider: SharePreferenceCache(),);
}

