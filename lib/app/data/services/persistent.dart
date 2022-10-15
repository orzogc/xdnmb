import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../widgets/dialog.dart';
import '../models/hive.dart';
import '../models/persistent.dart';
import 'settings.dart';
import 'xdnmb_client.dart';

class PersistentDataService extends GetxService {
  static PersistentDataService get to => Get.find<PersistentDataService>();

  late final Box _dataBox;

  final RxBool isKeyboardVisible = false.obs;

  final RxBool isReady = false.obs;

  String get notice => _dataBox.get(PersistentData.notice, defaultValue: '');

  set notice(String notice) => _dataBox.put(PersistentData.notice, notice);

  double? get keyboardHeight => _dataBox.get(PersistentData.keyboardHeight);

  set keyboardHeight(double? height) =>
      _dataBox.put(PersistentData.keyboardHeight, height);

  String? get pictureDirectory => _dataBox.get(PersistentData.pictureDirectory);

  set pictureDirectory(String? path) =>
      _dataBox.put(PersistentData.pictureDirectory, path);

  int get diceLower => _dataBox.get(PersistentData.diceLower, defaultValue: 1);

  set diceLower(int lower) => _dataBox.put(PersistentData.diceLower, lower);

  int get diceUpper =>
      _dataBox.get(PersistentData.diceUpper, defaultValue: 100);

  set diceUpper(int upper) => _dataBox.put(PersistentData.diceUpper, upper);

  late final ValueListenable<Box> keyboardHeightListenable;

  Future<void> updateNotice() async {
    final notice = await XdnmbClientService.to.client.getNotice();
    if (notice.isValid && this.notice != notice.content) {
      this.notice = notice.content;
      SettingsService.to.showNotice = true;
    }
  }

  Future<void> updateNoticeAndShow(Notice notice) async {
    final settings = SettingsService.to;
    if (settings.isReady.value && notice.isValid) {
      if (this.notice != notice.content) {
        this.notice = notice.content;
        settings.showNotice = true;

        await showNoticeDialog(showCheckbox: true);
      } else if (settings.showNotice) {
        await showNoticeDialog(showCheckbox: true);
      }
    }
  }

  @override
  void onInit() async {
    super.onInit();

    _dataBox = await Hive.openBox(HiveBoxName.data);

    if (GetPlatform.isMobile) {
      final contorller = KeyboardVisibilityController();
      contorller.onChange.listen((visible) {
        isKeyboardVisible.value = visible;

        if (visible) {
          final height = EdgeInsets.fromWindowPadding(
                  WidgetsBinding.instance.window.viewInsets,
                  WidgetsBinding.instance.window.devicePixelRatio)
              .bottom;
          if (height > 1.0 && keyboardHeight != height) {
            keyboardHeight = height;
          }
        }
      });
    }

    keyboardHeightListenable =
        _dataBox.listenable(keys: [PersistentData.keyboardHeight]);

    isReady.value = true;

    debugPrint('读取保存数据成功');
  }

  @override
  void onClose() async {
    await _dataBox.close();
    isReady.value = false;

    super.onClose();
  }
}
