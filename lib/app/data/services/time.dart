import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// TODO: 相对时间
class TimeService extends GetxService {
  static TimeService get to => Get.find<TimeService>();

  late final Timer _timer;

  DateTime now = DateTime.now().toLocal();

  @override
  void onInit() {
    super.onInit();

    _timer = Timer.periodic(
        const Duration(minutes: 1), (_) => now = DateTime.now().toLocal());

    debugPrint('设置时间成功');
  }

  @override
  void onClose() {
    _timer.cancel();

    super.onClose();
  }
}
