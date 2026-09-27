import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'extension.dart';

/// Thin wrapper around Firebase Analytics for the car-signal trial and paywall events.
/// Widget tests never call Firebase.initializeApp(), so screens must not call FirebaseAnalytics.instance directly.
/// They go through [SignalAnalytics.log] instead.
class SignalAnalytics {
  /// The real sender, replaced in tests with a no-op or a recorder
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? parameters) send =
      (name, parameters) => FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  /// car_trial_entry_view fires once per app launch; this flag is the "once" part
  static bool trialEntryViewLogged = false;

  static Future<void> log(String name, [Map<String, Object>? parameters]) async {
    "analytics: $name $parameters".debugPrint();
    try {
      await send(name, parameters);
    } catch (e) {
      "analytics error: $e".debugPrint();
    }
  }

  /// Resets the sender and the entry-view flag; tests call this between cases
  @visibleForTesting
  static void reset() {
    send = (name, parameters) => FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    trialEntryViewLogged = false;
  }
}
