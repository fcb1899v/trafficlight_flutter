// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'レッツ・シン・ゴー';

  @override
  String get thisApp => 'このアプリはリアルな交通信号シミュレーターです。';

  @override
  String get settingsTitle => '設定';

  @override
  String get premiumPlan => 'プレミアムプラン';

  @override
  String get plan => 'プラン';

  @override
  String get free => 'フリー';

  @override
  String get premium => 'プレミアム';

  @override
  String get upgrade => 'アップグレード';

  @override
  String get toUpgrade => 'アップグレードする';

  @override
  String get restore => '復元';

  @override
  String get toRestore => '復元する';

  @override
  String get successPurchase => '購入が完了しました';

  @override
  String get successRestore => '復元が完了しました';

  @override
  String get errorPurchase => '購入エラー';

  @override
  String get errorRestore => '復元エラー';

  @override
  String get readError => '読み込みエラー';

  @override
  String get failPurchase => '購入できませんでした。';

  @override
  String get failRestore => '過去の購入履歴が見つかりませんでした。';

  @override
  String get purchaseCancelledMessage => '購入をキャンセルしました';

  @override
  String get paymentPendingMessage => 'お支払いが保留中です。\nストアをご確認ください。';

  @override
  String get purchaseInvalidMessage => 'お支払いが保留中の商品です。\nストアをご確認ください。';

  @override
  String get purchaseNotAllowedMessage => '購入できませんでした。\nお支払い方法をご確認ください。';

  @override
  String get networkErrorMessage => 'インターネットに接続してください。';

  @override
  String get loading => '読み込み中・・・';

  @override
  String get loadingError => '読み込み失敗';

  @override
  String get pushButton => '押しボタン';

  @override
  String get pedestrianSignal => '歩行者用信号';

  @override
  String get carSignal => '車用信号';

  @override
  String get noAds => '広告非表示';

  @override
  String get timeSettings => '時間の設定';

  @override
  String get timeUnit => ' [秒]';

  @override
  String get waitTime => '赤信号の待ち時間';

  @override
  String get goTime => '青信号の点灯時間';

  @override
  String get flashTime => '青信号の点滅時間';

  @override
  String get soundSettings => '音の設定';

  @override
  String get crosswalkSound => '横断歩道の音';

  @override
  String get toSettings => '設定';

  @override
  String get toOn => 'オン';

  @override
  String get toOff => 'オフ';

  @override
  String get toNew => '新式';

  @override
  String get toOld => '旧式';

  @override
  String get confirmed => '確認';
}
