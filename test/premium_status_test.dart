// The stored key_premium follows RevenueCat: reset when no entitlement is active, kept when RevenueCat cannot be reached.
// The 999-cycle unlock (key_cycleUnlocked) is never touched.

import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalbutton/extension.dart';
import 'package:signalbutton/plan_provider.dart';

EntitlementInfo entitlement(String id, bool active) =>
  EntitlementInfo(id, active, false, '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z', 'lifetime', false);

CustomerInfo info({bool cars = false, bool noAds = false}) {
  final all = {
    'signal_for_cars': entitlement('signal_for_cars', cars),
    'no_ads': entitlement('no_ads', noAds),
  };
  final active = Map.of(all)..removeWhere((_, e) => !e.isActive);
  return CustomerInfo(EntitlementInfos(all, active), {}, [], [], [], '2026-01-01T00:00:00Z', 'user', {}, '2026-01-01T00:00:00Z');
}

Future<void> start(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  await Settings.init(cacheProvider: SharePreferenceCache());
}

void main() {
  tearDown(() => customerInfoSource = Purchases.getCustomerInfo);

  test('no active entitlement resets a stored purchase and keeps the cycle unlock', () async {
    await start({'flutter.key_premium': true, 'flutter.key_cycleUnlocked': true});
    customerInfoSource = () async => info();
    expect(await getInitialPremiumStatus(), isFalse);
    expect("premium".getSettingsValueBool(true), isFalse);
    expect("cycleUnlocked".getSettingsValueBool(false), isTrue);
  });

  test('only one of the two entitlements is not premium', () async {
    await start({'flutter.key_premium': true});
    customerInfoSource = () async => info(cars: true);
    expect(await getInitialPremiumStatus(), isFalse);
    expect("premium".getSettingsValueBool(true), isFalse);
  });

  test('both entitlements store premium', () async {
    await start({});
    customerInfoSource = () async => info(cars: true, noAds: true);
    expect(await getInitialPremiumStatus(), isTrue);
    expect("premium".getSettingsValueBool(false), isTrue);
  });

  test('an unreachable RevenueCat keeps a stored purchase', () async {
    await start({'flutter.key_premium': true});
    customerInfoSource = () async => throw Exception('offline');
    expect(await getInitialPremiumStatus(), isTrue);
    expect("premium".getSettingsValueBool(false), isTrue);
  });

  test('an unreachable RevenueCat keeps a free user free', () async {
    await start({});
    customerInfoSource = () async => throw Exception('offline');
    expect(await getInitialPremiumStatus(), isFalse);
  });
}
