import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'extension.dart';
import 'firebase_options.dart';
import 'plan_provider.dart';
import 'constant.dart';
import 'homepage.dart';
import 'settings.dart';
import 'upgrade.dart';

/// Notifiers for time-related settings (Riverpod 3 - StateProvider replacement)
class WaitTimeNotifier extends Notifier<int> {
  final int? _initial;
  WaitTimeNotifier([this._initial]);
  @override
  int build() => _initial ?? initialWaitTime;
  void setTime(int value) => state = value;
}

class GoTimeNotifier extends Notifier<int> {
  final int? _initial;
  GoTimeNotifier([this._initial]);
  @override
  int build() => _initial ?? initialGoTime;
  void setTime(int value) => state = value;
}

class FlashTimeNotifier extends Notifier<int> {
  final int? _initial;
  FlashTimeNotifier([this._initial]);
  @override
  int build() => _initial ?? initialFlashTime;
  void setTime(int value) => state = value;
}

class YellowTimeNotifier extends Notifier<int> {
  final int? _initial;
  YellowTimeNotifier([this._initial]);
  @override
  int build() => _initial ?? initialYellowTime;
  void setTime(int value) => state = value;
}

class ArrowTimeNotifier extends Notifier<int> {
  final int? _initial;
  ArrowTimeNotifier([this._initial]);
  @override
  int build() => _initial ?? initialArrowTime;
  void setTime(int value) => state = value;
}

class IsSoundNotifier extends Notifier<bool> {
  final bool? _initial;
  IsSoundNotifier([this._initial]);
  @override
  bool build() => _initial ?? true;
  void setSound(bool value) => state = value;
}

/// State providers for time-related settings
/// These providers manage the app's timing configuration across the entire app
final waitTimeProvider = NotifierProvider<WaitTimeNotifier, int>(WaitTimeNotifier.new);
final goTimeProvider = NotifierProvider<GoTimeNotifier, int>(GoTimeNotifier.new);
final flashTimeProvider = NotifierProvider<FlashTimeNotifier, int>(FlashTimeNotifier.new);
final yellowTimeProvider = NotifierProvider<YellowTimeNotifier, int>(YellowTimeNotifier.new);
final arrowTimeProvider = NotifierProvider<ArrowTimeNotifier, int>(ArrowTimeNotifier.new);
final isSoundProvider = NotifierProvider<IsSoundNotifier, bool>(IsSoundNotifier.new);

/// Main application entry point
/// Initializes all required services and configurations
// No ATT call here. On iOS the UMP form shows Google's IDFA explainer and then
// raises the system ATT prompt itself, so asking again from the app put a second
// explainer in front of a user who had already answered. Removed in NEO first;
// see 03_Developer/technical/2026-08-25_elevatorneo_att_gate_removal.md
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
  // Get initial premium status without using a notifier (notifier needs Riverpod)
  final initialPremium = await getInitialPremiumStatus();
  // Load saved time settings from local storage
  final savedWaitTime = "wait".getSettingsValueInt(initialWaitTime);
  final savedGoTime = "go".getSettingsValueInt(initialGoTime);
  final savedFlashTime = "flash".getSettingsValueInt(initialFlashTime);
  final savedYellowTime = "yellow".getSettingsValueInt(initialYellowTime);
  final savedArrowTime = "arrow".getSettingsValueInt(initialArrowTime);
  final savedIsSound = "sound".getSettingsValueBool(true);
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  // Initialize App Tracking Transparency
  // Run app with provider overrides for saved settings
  runApp(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(isPremium: initialPremium))),
      waitTimeProvider.overrideWith(() => WaitTimeNotifier(savedWaitTime)),
      goTimeProvider.overrideWith(() => GoTimeNotifier(savedGoTime)),
      flashTimeProvider.overrideWith(() => FlashTimeNotifier(savedFlashTime)),
      yellowTimeProvider.overrideWith(() => YellowTimeNotifier(savedYellowTime)),
      arrowTimeProvider.overrideWith(() => ArrowTimeNotifier(savedArrowTime)),
      isSoundProvider.overrideWith(() => IsSoundNotifier(savedIsSound)),
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

