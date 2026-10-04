// The app supports English and Japanese only; every other device language, Chinese included, resolves to English.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalbutton/l10n/app_localizations.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  test('only English and Japanese are supported', () {
    expect(supported.map((l) => l.languageCode).toSet(), {'en', 'ja'});
  });

  test('Chinese devices resolve to English, the first supported locale', () {
    for (final device in [
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
      const Locale('zh'),
    ]) {
      expect(basicLocaleListResolution([device], supported).languageCode, 'en', reason: '$device');
    }
  });

  test('English and Japanese devices keep their language', () {
    expect(basicLocaleListResolution([const Locale('ja', 'JP')], supported).languageCode, 'ja');
    expect(basicLocaleListResolution([const Locale('en', 'US')], supported).languageCode, 'en');
  });
}
