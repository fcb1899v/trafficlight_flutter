// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '操作乐趣交通信号';

  @override
  String get thisApp => '这个应用程序是一个逼真的交通信号模拟器。';

  @override
  String get settingsTitle => '设置';

  @override
  String get premiumPlan => '高级计划';

  @override
  String get plan => '计划';

  @override
  String get free => '免费';

  @override
  String get premium => '高级';

  @override
  String get upgrade => '升级';

  @override
  String get toUpgrade => '升级';

  @override
  String get restore => '恢复';

  @override
  String get toRestore => '恢复';

  @override
  String get successPurchase => '购买成功';

  @override
  String get successRestore => '恢复成功';

  @override
  String get errorPurchase => '购买错误';

  @override
  String get errorRestore => '恢复错误';

  @override
  String get readError => '读取错误';

  @override
  String get failPurchase => '无法购买。';

  @override
  String get failRestore => '未找到以前的购买记录。';

  @override
  String get purchaseCancelledMessage => '已取消购买';

  @override
  String get paymentPendingMessage => '支付正在等待中。\n请检查商店。';

  @override
  String get purchaseInvalidMessage => '无效的购买项目。\n请检查商店。';

  @override
  String get purchaseNotAllowedMessage => '无法购买。\n请检查您的支付方式。';

  @override
  String get networkErrorMessage => '请检查网络连接';

  @override
  String get loading => '正在加载...';

  @override
  String get loadingError => '加载失败';

  @override
  String get pushButton => '按键';

  @override
  String get pedestrianSignal => '行人信号灯';

  @override
  String get carSignal => '车辆信号灯';

  @override
  String get noAds => '无广告';

  @override
  String get timeSettings => '时间设置';

  @override
  String get timeUnit => ' [秒]';

  @override
  String get waitTime => '红灯等待时间';

  @override
  String get goTime => '绿灯点亮时间';

  @override
  String get flashTime => '绿灯闪烁时间';

  @override
  String get soundSettings => '声音设置';

  @override
  String get crosswalkSound => '人行横道声音';

  @override
  String get toSettings => '设置';

  @override
  String get toOn => '开';

  @override
  String get toOff => '关';

  @override
  String get toNew => '新式';

  @override
  String get toOld => '旧式';

  @override
  String get confirmed => '确认';
}
