import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/forum.dart';
import '../models/hive.dart';
import '../models/settings.dart';

class SettingsService extends GetxService {
  static SettingsService get to => Get.find<SettingsService>();

  late final Box _settingsBox;

  final RxBool hasBeenDarkMode = false.obs;

  final RxBool isReady = false.obs;

  bool get isDarkMode =>
      _settingsBox.get(Settings.isDarkMode, defaultValue: Get.isDarkMode);

  set isDarkMode(bool isDarkMode) =>
      _settingsBox.put(Settings.isDarkMode, isDarkMode);

  bool get showNotice =>
      _settingsBox.get(Settings.showNotice, defaultValue: true);

  set showNotice(bool showNotice) =>
      _settingsBox.put(Settings.showNotice, showNotice);

  ForumData get initialForum => _settingsBox.get(Settings.initialForum,
      defaultValue: ForumData(
          id: 1,
          name: '综合线',
          displayName: '综合线',
          message: '主时间线',
          maxPage: 20,
          isTimeline: true));

  set initialForum(ForumData forum) =>
      _settingsBox.put(Settings.initialForum, forum);

  bool get showImage =>
      _settingsBox.get(Settings.showImage, defaultValue: true);

  set showImage(bool showImage) =>
      _settingsBox.put(Settings.showImage, showImage);

  bool get isWatermark =>
      _settingsBox.get(Settings.isWatermark, defaultValue: false);

  set isWatermark(bool isWatermark) =>
      _settingsBox.put(Settings.isWatermark, isWatermark);

  bool get isJumpToLastBrowsePage =>
      _settingsBox.get(Settings.isJumpToLastBrowsePage, defaultValue: true);

  set isJumpToLastBrowsePage(bool isJumpToLastBrowseHistory) => _settingsBox
      .put(Settings.isJumpToLastBrowsePage, isJumpToLastBrowseHistory);

  bool get isJumpToLastBrowsePosition =>
      _settingsBox.get(Settings.isJumpToLastBrowsePosition, defaultValue: true);

  set isJumpToLastBrowsePosition(bool isJumpToLastBrowsePosition) =>
      _settingsBox.put(
          Settings.isJumpToLastBrowsePosition, isJumpToLastBrowsePosition);

  String get feedUuid => _settingsBox.get(Settings.feedUuid);

  set feedUuid(String uuid) => _settingsBox.put(Settings.feedUuid, uuid);

  late final ValueListenable<Box> initialForumListenable;

  late final ValueListenable<Box> showImageListenable;

  late final ValueListenable<Box> isWatermarkListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePageListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePositionListenable;

  late final ValueListenable<Box> feedUuidListenable;

  Future<void> checkDarkMode() async {
    // 等待生效
    while (isDarkMode != Get.isDarkMode) {
      debugPrint('正在切换白天/黑夜模式');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    hasBeenDarkMode.value = Get.isDarkMode;
  }

  @override
  void onInit() async {
    super.onInit();

    _settingsBox = await Hive.openBox(HiveBoxName.settings);

    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    _settingsBox.watch(key: Settings.isDarkMode).listen((event) async {
      Get.changeThemeMode(
          event.value as bool ? ThemeMode.dark : ThemeMode.light);
      await checkDarkMode();
    });

    if (!_settingsBox.containsKey(Settings.feedUuid)) {
      feedUuid = const Uuid().v4();
    }

    initialForumListenable =
        _settingsBox.listenable(keys: [Settings.initialForum]);
    showImageListenable = _settingsBox.listenable(keys: [Settings.showImage]);
    isWatermarkListenable =
        _settingsBox.listenable(keys: [Settings.isWatermark]);
    isJumpToLastBrowsePageListenable =
        _settingsBox.listenable(keys: [Settings.isJumpToLastBrowsePage]);
    isJumpToLastBrowsePositionListenable =
        _settingsBox.listenable(keys: [Settings.isJumpToLastBrowsePosition]);
    feedUuidListenable = _settingsBox.listenable(keys: [Settings.feedUuid]);

    isReady.value = true;
    await checkDarkMode();

    debugPrint('读取设置数据成功');
  }

  @override
  void onClose() async {
    await _settingsBox.close();
    isReady.value = false;

    super.onClose();
  }
}
