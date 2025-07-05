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

/// State providers for time-related settings
/// These providers manage the app's timing configuration across the entire app
final waitTimeProvider = StateProvider<int>((ref) => initialWaitTime);
final goTimeProvider = StateProvider<int>((ref) => initialGoTime);
final flashTimeProvider = StateProvider<int>((ref) => initialFlashTime);
final yellowTimeProvider = StateProvider<int>((ref) => initialYellowTime);
final arrowTimeProvider = StateProvider<int>((ref) => initialArrowTime);
final isSoundProvider = StateProvider<bool>((ref) => true);

/// Main application entry point
/// Initializes all required services and configurations
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Set device orientation to portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Configure system UI for edge-to-edge display
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize settings storage
  await Settings.init(cacheProvider: SharePreferenceCache(),);
  // Initialize RevenueCat for in-app purchases BEFORE creating planNotifier
  final apiKey = dotenv.get(revenueCatApiKey);
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(PurchasesConfiguration(apiKey));
  await Purchases.enableAdServicesAttributionTokenCollection();
  // Initialize premium status AFTER RevenueCat is configured
  final planNotifier = PlanNotifier();
  await planNotifier.initializePremiumStatus();
  // Load saved time settings from local storage
  final savedWaitTime = "wait".getSettingsValueInt(initialWaitTime);
  final savedGoTime = "go".getSettingsValueInt(initialGoTime);
  final savedFlashTime = "flash".getSettingsValueInt(initialFlashTime);
  final savedYellowTime = "yellow".getSettingsValueInt(initialYellowTime);
  final savedArrowTime = "arrow".getSettingsValueInt(initialArrowTime);
  final savedIsSound = "sound".getSettingsValueBool(true);
  // Initialize Firebase App Check for security
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  // Initialize App Tracking Transparency
  await initATTPlugin();
  // Run app with provider overrides for saved settings
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
}

/// Main application widget
/// Configures the app theme, localization, and navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Configure localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // App metadata
      title: 'LETS SIGNAL',
      theme: ThemeData(colorScheme: const ColorScheme.light(primary: greenColor)),
      debugShowCheckedModeBanner: false,
      // Set home page
      home: const HomePage(),
      // Define app routes
      routes: {
        '/h' : (_) => const HomePage(),
        '/s' : (_) => const SettingsPage(),
        '/u' : (_) => const UpgradePage(),
      },
      // Configure navigation observers for analytics
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        RouteObserver<ModalRoute>()
      ],
    );
  }
}

/// Initialize App Tracking Transparency for iOS/macOS
/// Requests user permission for tracking if not already determined
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
