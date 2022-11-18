import 'dart:async';
import 'dart:math';

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

  static late final bool isFirstLaunched;

  static late final bool isShowGuide;

  late final Box _dataBox;

  final RxBool isKeyboardVisible = false.obs;

  final ValueNotifier<double> bottomHeight = ValueNotifier(0.0);

  double _maxBottomHeight = 0.0;

  final RxBool isReady = false.obs;

  bool get firstLaunched =>
      _dataBox.get(PersistentData.firstLaunched, defaultValue: true);

  set firstLaunched(bool firstLaunched) =>
      _dataBox.put(PersistentData.firstLaunched, firstLaunched);

  String get notice => _dataBox.get(PersistentData.notice, defaultValue: '');

  set notice(String notice) => _dataBox.put(PersistentData.notice, notice);

  double? get keyboardHeight =>
      _dataBox.get(PersistentData.keyboardHeight, defaultValue: null);

  set keyboardHeight(double? height) =>
      _dataBox.put(PersistentData.keyboardHeight, height);

  String? get pictureDirectory =>
      _dataBox.get(PersistentData.pictureDirectory, defaultValue: null);

  set pictureDirectory(String? path) =>
      _dataBox.put(PersistentData.pictureDirectory, path);

  int get diceLower => _dataBox.get(PersistentData.diceLower, defaultValue: 1);

  set diceLower(int lower) => _dataBox.put(PersistentData.diceLower, lower);

  int get diceUpper =>
      _dataBox.get(PersistentData.diceUpper, defaultValue: 100);

  set diceUpper(int upper) => _dataBox.put(PersistentData.diceUpper, upper);

  bool get showGuide =>
      !SettingsService.isBackdropUI &&
      _dataBox.get(PersistentData.showGuide, defaultValue: true);

  set showGuide(bool showGuide) =>
      _dataBox.put(PersistentData.showGuide, showGuide);

  bool get showBackdropGuide =>
      SettingsService.isBackdropUI &&
      _dataBox.get(PersistentData.showBackdropGuide, defaultValue: true);

  set showBackdropGuide(bool showBackdropGuide) =>
      _dataBox.put(PersistentData.showBackdropGuide, showBackdropGuide);

  bool get shouldShowGuide => showBackdropGuide || showGuide;

  DateTime? get updateForumListTime =>
      _dataBox.get(PersistentData.updateForumListTime, defaultValue: null);

  set updateForumListTime(DateTime? time) =>
      _dataBox.put(PersistentData.updateForumListTime, time);

  int get controllerStackListIndex =>
      _dataBox.get(PersistentData.controllerStackListIndex, defaultValue: 0);

  set controllerStackListIndex(int index) =>
      _dataBox.put(PersistentData.controllerStackListIndex, index);

  StreamSubscription<bool>? _keyboardSubscription;

  static Future<void> getData() async {
    final box = await Hive.openBox(HiveBoxName.data);

    isFirstLaunched = box.get(PersistentData.firstLaunched, defaultValue: true);
  }

  static double _bottomHeight() => EdgeInsets.fromWindowPadding(
          WidgetsBinding.instance.window.viewInsets,
          WidgetsBinding.instance.window.devicePixelRatio)
      .bottom;

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
      while (!client.finishGettingNotice) {
        debugPrint('正在等待获取X岛公告');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (notice.isNotEmpty) {
        await showNoticeDialog(showCheckbox: true);
      }
    }
  }

  void updateKeyboardHeight() {
    if (GetPlatform.isMobile) {
      final height = _bottomHeight();

      _maxBottomHeight = max(_maxBottomHeight, height);

      if (bottomHeight.value > height &&
          _maxBottomHeight > 0.0 &&
          keyboardHeight != _maxBottomHeight) {
        keyboardHeight = _maxBottomHeight;
      }

      bottomHeight.value = height;
    }
  }

  @override
  void onInit() async {
    super.onInit();

    _dataBox = await Hive.openBox(HiveBoxName.data);
    isShowGuide = shouldShowGuide;

    if (GetPlatform.isMobile) {
      bottomHeight.value = _bottomHeight();

      _keyboardSubscription = KeyboardVisibilityController()
          .onChange
          .listen((visible) => isKeyboardVisible.value = visible);
    }

    isReady.value = true;

    debugPrint('读取保存数据成功');
  }

  @override
  void onClose() async {
    await _dataBox.close();
    await _keyboardSubscription?.cancel();
    isReady.value = false;

    super.onClose();
  }
}
