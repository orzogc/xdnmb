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

  static const Duration updateForumListInterval = Duration(hours: 6);

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

  bool get showGuide =>
      _dataBox.get(PersistentData.showGuide, defaultValue: true);

  set showGuide(bool showGuide) =>
      _dataBox.put(PersistentData.showGuide, showGuide);

  DateTime? get updateForumListTime =>
      _dataBox.get(PersistentData.updateForumListTime, defaultValue: null);

  set updateForumListTime(DateTime? time) =>
      _dataBox.put(PersistentData.updateForumListTime, time);

  void saveNotice(Notice notice) {
    if (notice.isValid && this.notice != notice.content) {
      this.notice = notice.content;
      SettingsService.to.showNotice = true;
    }
  }

  Future<void> updateNotice() async =>
      saveNotice(await XdnmbClientService.to.client.getNotice());

  Future<void> showNotice() async {
    if (SettingsService.to.showNotice) {
      final client = XdnmbClientService.to;
      while (!client.hasGotNotice) {
        debugPrint('正在等待获取公告');
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await showNoticeDialog(showCheckbox: true);
    }
  }

  void updateKeyboardHeight() {
    if (GetPlatform.isMobile) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (isKeyboardVisible.value) {
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
  }

  @override
  void onInit() async {
    super.onInit();

    _dataBox = await Hive.openBox(HiveBoxName.data);

    if (GetPlatform.isMobile) {
      KeyboardVisibilityController()
          .onChange
          .listen((visible) => isKeyboardVisible.value = visible);
    }

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
