import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class _CustomMessages implements LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => '前';

  @override
  String suffixFromNow() => '后';

  @override
  String lessThanOneMinute(int seconds) =>
      seconds < 10 ? '几秒' : (seconds < 20 ? '十几秒' : '几十秒');

  @override
  String aboutAMinute(int minutes) => '1分钟';

  @override
  String minutes(int minutes) => '$minutes分钟';

  @override
  String aboutAnHour(int minutes) => '1小时';

  @override
  String hours(int hours) => '$hours小时';

  @override
  String aDay(int hours) => '1天';

  @override
  String days(int days) => '$days天';

  @override
  String aboutAMonth(int days) => '1个月';

  @override
  String months(int months) => '$months个月';

  @override
  String aboutAYear(int year) => '1年';

  @override
  String years(int years) => '$years年';

  @override
  String wordSeparator() => '';
}

class TimeService extends GetxService {
  static TimeService get to => Get.find<TimeService>();

  late final Timer _timer;

  DateTime now = DateTime.now().toLocal();

  final RxBool isReady = false.obs;

  void updateTime() => now = DateTime.now().toLocal();

  String relativeTime(DateTime time) =>
      time.isBefore(now) ? format(time, clock: now) : '来自未来';

  @override
  void onInit() {
    super.onInit();

    setLocaleMessages('zh', _CustomMessages());
    setDefaultLocale('zh');
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => updateTime());

    isReady.value = true;
    debugPrint('设置时间成功');
  }

  @override
  void onClose() {
    _timer.cancel();
    isReady.value = false;

    super.onClose();
  }
}
