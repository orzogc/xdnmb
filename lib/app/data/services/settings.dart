import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/forum.dart';
import '../models/hive.dart';
import '../models/settings.dart';
import 'image.dart';

final ForumData defaultForum = ForumData(
    id: 1,
    name: '综合线',
    displayName: '综合线',
    message: '主时间线',
    maxPage: 20,
    isTimeline: true);

/// 设置服务
class SettingsService extends GetxService {
  static const double minDrawerEdgeDragWidthRatio = 0.1;

  static const double maxDrawerEdgeDragWidthRatio = 0.5;

  static SettingsService get to => Get.find<SettingsService>();

  static late final bool isRestoreForumPage;

  static late final bool isFixMissingFont;

  static late final bool isShowGuide;

  static late final bool isBackdropUI;

  late final Box _settingsBox;

  final RxBool hasBeenDarkMode = false.obs;

  late final RxDouble _drawerDragRatio;

  final RxBool isReady = false.obs;

  bool get isDarkMode =>
      _settingsBox.get(Settings.isDarkMode, defaultValue: Get.isDarkMode);

  set isDarkMode(bool isDarkMode) =>
      _settingsBox.put(Settings.isDarkMode, isDarkMode);

  bool get showNotice =>
      _settingsBox.get(Settings.showNotice, defaultValue: true);

  set showNotice(bool showNotice) =>
      _settingsBox.put(Settings.showNotice, showNotice);

  bool get isRestoreTabs =>
      _settingsBox.get(Settings.isRestoreTabs, defaultValue: true);

  set isRestoreTabs(bool isRestoreTabs) =>
      _settingsBox.put(Settings.isRestoreTabs, isRestoreTabs);

  ForumData get initialForum =>
      _settingsBox.get(Settings.initialForum, defaultValue: defaultForum);

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

  bool get hideFloatingButton =>
      _settingsBox.get(Settings.hideFloatingButton, defaultValue: false);

  set hideFloatingButton(bool hideFloatingButton) =>
      _settingsBox.put(Settings.hideFloatingButton, hideFloatingButton);

  bool get isJumpToLastBrowsePage =>
      _settingsBox.get(Settings.isJumpToLastBrowsePage, defaultValue: true);

  set isJumpToLastBrowsePage(bool isJumpToLastBrowseHistory) => _settingsBox
      .put(Settings.isJumpToLastBrowsePage, isJumpToLastBrowseHistory);

  bool get isJumpToLastBrowsePosition =>
      _settingsBox.get(Settings.isJumpToLastBrowsePosition, defaultValue: true);

  set isJumpToLastBrowsePosition(bool isJumpToLastBrowsePosition) =>
      _settingsBox.put(
          Settings.isJumpToLastBrowsePosition, isJumpToLastBrowsePosition);

  bool get isAfterPostRefresh =>
      _settingsBox.get(Settings.isAfterPostRefresh, defaultValue: true);

  set isAfterPostRefresh(bool isAfterPostRefresh) =>
      _settingsBox.put(Settings.isAfterPostRefresh, isAfterPostRefresh);

  bool get dismissibleTab =>
      _settingsBox.get(Settings.dismissibleTab, defaultValue: false);

  set dismissibleTab(bool dismissibleTab) =>
      _settingsBox.put(Settings.dismissibleTab, dismissibleTab);

  String get feedId => _settingsBox.get(Settings.feedId);

  set feedId(String feedId) => _settingsBox.put(Settings.feedId, feedId);

  String? get saveImagePath =>
      _settingsBox.get(Settings.saveImagePath, defaultValue: null);

  set saveImagePath(String? directory) {
    _settingsBox.put(Settings.saveImagePath, directory);
    ImageService.savePath = directory;
  }

  bool get addBlueIslandEmoticons =>
      _settingsBox.get(Settings.addBlueIslandEmoticons, defaultValue: true);

  set addBlueIslandEmoticons(bool addBlueIslandEmoticons) =>
      _settingsBox.put(Settings.addBlueIslandEmoticons, addBlueIslandEmoticons);

  bool get restoreForumPage =>
      _settingsBox.get(Settings.restoreForumPage, defaultValue: false);

  set restoreForumPage(bool restoreForumPage) =>
      _settingsBox.put(Settings.restoreForumPage, restoreForumPage);

  double get drawerEdgeDragWidthRatio =>
      (_settingsBox.get(Settings.drawerEdgeDragWidthRatio, defaultValue: 0.25)
              as double)
          .clamp(minDrawerEdgeDragWidthRatio, maxDrawerEdgeDragWidthRatio);

  set drawerEdgeDragWidthRatio(double ratio) {
    ratio =
        ratio.clamp(minDrawerEdgeDragWidthRatio, maxDrawerEdgeDragWidthRatio);
    _settingsBox.put(Settings.drawerEdgeDragWidthRatio, ratio);
    _drawerDragRatio.value = ratio;
  }

  int get imageDisposeDistance => max(
      _settingsBox.get(Settings.imageDisposeDistance, defaultValue: 120), 0);

  set imageDisposeDistance(int distance) =>
      _settingsBox.put(Settings.imageDisposeDistance, max(distance, 0));

  double get fixedImageDisposeRatio =>
      (_settingsBox.get(Settings.fixedImageDisposeRatio, defaultValue: 0.35)
              as double)
          .clamp(0.0, 1.0);

  set fixedImageDisposeRatio(double ratio) =>
      _settingsBox.put(Settings.fixedImageDisposeRatio, ratio.clamp(0.0, 1.0));

  bool get fixMissingFont =>
      _settingsBox.get(Settings.fixMissingFont, defaultValue: false);

  set fixMissingFont(bool fixMissingFont) =>
      _settingsBox.put(Settings.fixMissingFont, fixMissingFont);

  bool get showGuide =>
      !SettingsService.isBackdropUI &&
      _settingsBox.get(Settings.showGuide, defaultValue: true);

  set showGuide(bool showGuide) =>
      _settingsBox.put(Settings.showGuide, showGuide);

  bool get showBackdropGuide =>
      SettingsService.isBackdropUI &&
      _settingsBox.get(Settings.showBackdropGuide, defaultValue: true);

  set showBackdropGuide(bool showBackdropGuide) =>
      _settingsBox.put(Settings.showBackdropGuide, showBackdropGuide);

  bool get shouldShowGuide => showBackdropGuide || showGuide;

  bool get backdropUI =>
      _settingsBox.get(Settings.backdropUI, defaultValue: GetPlatform.isIOS);

  set backdropUI(bool backdropUi) =>
      _settingsBox.put(Settings.backdropUI, backdropUi);

  bool get compactBackdrop =>
      _settingsBox.get(Settings.compactBackdrop, defaultValue: false);

  set compactBackdrop(bool compactBackdrop) =>
      _settingsBox.put(Settings.compactBackdrop, compactBackdrop);

  double get swipeablePageDragWidthRatio => _settingsBox
      .get(Settings.swipeablePageDragWidthRatio, defaultValue: 0.25);

  set swipeablePageDragWidthRatio(double ratio) =>
      _settingsBox.put(Settings.swipeablePageDragWidthRatio, ratio);

  double get frontLayerDragHeightRatio =>
      _settingsBox.get(Settings.frontLayerDragHeightRatio, defaultValue: 0.20);

  set frontLayerDragHeightRatio(double ratio) =>
      _settingsBox.put(Settings.frontLayerDragHeightRatio, ratio);

  double get backLayerDragHeightRatio =>
      _settingsBox.get(Settings.backLayerDragHeightRatio, defaultValue: 0.10);

  set backLayerDragHeightRatio(double ratio) =>
      _settingsBox.put(Settings.backLayerDragHeightRatio, ratio);

  double get drawerDragRatio => _drawerDragRatio.value;

  late final ValueListenable<Box> isRestoreTabsListenable;

  late final ValueListenable<Box> initialForumListenable;

  late final ValueListenable<Box> showImageListenable;

  late final ValueListenable<Box> isWatermarkListenable;

  late final ValueListenable<Box> hideFloatingButtonListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePageListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePositionListenable;

  late final ValueListenable<Box> isAfterPostRefreshListenable;

  late final ValueListenable<Box> dismissibleTabListenable;

  late final ValueListenable<Box> feedIdListenable;

  late final ValueListenable<Box> saveImagePathListenable;

  late final ValueListenable<Box> addBlueIslandEmoticonsListenable;

  late final ValueListenable<Box> restoreForumPageListenable;

  late final ValueListenable<Box> drawerEdgeDragWidthRatioListenable;

  late final ValueListenable<Box> imageDisposeDistanceListenable;

  late final ValueListenable<Box> fixedImageDisposeRatioListenable;

  late final ValueListenable<Box> fixMissingFontListenable;

  late final ValueListenable<Box> showGuideListenable;

  late final ValueListenable<Box> backdropUIListenable;

  late final ValueListenable<Box> compactBackdropListenable;

  late final ValueListenable<Box> swipeablePageDragWidthRatioListenable;

  late final ValueListenable<Box> frontLayerDragHeightRatioListenable;

  late final ValueListenable<Box> backLayerDragHeightRatioListenable;

  late final StreamSubscription<BoxEvent> _darkModeSubscription;

  static Future<void> getSettings() async {
    final box = await Hive.openBox(HiveBoxName.settings);

    ImageService.savePath = box.get(Settings.saveImagePath, defaultValue: null);
    // 是否修复字体，结果保存在`fixMissingFont`
    isFixMissingFont = box.get(Settings.fixMissingFont, defaultValue: false);
    isRestoreForumPage =
        box.get(Settings.restoreForumPage, defaultValue: false);
    isBackdropUI =
        box.get(Settings.backdropUI, defaultValue: GetPlatform.isIOS);
  }

  void updateSaveImagePath() {
    if (saveImagePath != ImageService.savePath) {
      saveImagePath = ImageService.savePath;
    }
  }

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
    isShowGuide = shouldShowGuide;

    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    _darkModeSubscription =
        _settingsBox.watch(key: Settings.isDarkMode).listen((event) async {
      Get.changeThemeMode(
          event.value as bool ? ThemeMode.dark : ThemeMode.light);
      await checkDarkMode();
    });

    if (!_settingsBox.containsKey(Settings.feedId)) {
      feedId = const Uuid().v4();
    }

    isRestoreTabsListenable =
        _settingsBox.listenable(keys: [Settings.isRestoreTabs]);
    initialForumListenable = _settingsBox
        .listenable(keys: [Settings.isRestoreTabs, Settings.initialForum]);
    showImageListenable = _settingsBox.listenable(keys: [Settings.showImage]);
    isWatermarkListenable =
        _settingsBox.listenable(keys: [Settings.isWatermark]);
    hideFloatingButtonListenable =
        _settingsBox.listenable(keys: [Settings.hideFloatingButton]);
    isJumpToLastBrowsePageListenable =
        _settingsBox.listenable(keys: [Settings.isJumpToLastBrowsePage]);
    isJumpToLastBrowsePositionListenable = _settingsBox.listenable(keys: [
      Settings.isJumpToLastBrowsePage,
      Settings.isJumpToLastBrowsePosition,
    ]);
    isAfterPostRefreshListenable =
        _settingsBox.listenable(keys: [Settings.isAfterPostRefresh]);
    dismissibleTabListenable =
        _settingsBox.listenable(keys: [Settings.dismissibleTab]);
    feedIdListenable = _settingsBox.listenable(keys: [Settings.feedId]);
    saveImagePathListenable =
        _settingsBox.listenable(keys: [Settings.saveImagePath]);
    addBlueIslandEmoticonsListenable =
        _settingsBox.listenable(keys: [Settings.addBlueIslandEmoticons]);
    restoreForumPageListenable =
        _settingsBox.listenable(keys: [Settings.restoreForumPage]);
    drawerEdgeDragWidthRatioListenable =
        _settingsBox.listenable(keys: [Settings.drawerEdgeDragWidthRatio]);
    imageDisposeDistanceListenable =
        _settingsBox.listenable(keys: [Settings.imageDisposeDistance]);
    fixedImageDisposeRatioListenable =
        _settingsBox.listenable(keys: [Settings.fixedImageDisposeRatio]);
    fixMissingFontListenable =
        _settingsBox.listenable(keys: [Settings.fixMissingFont]);
    showGuideListenable = _settingsBox.listenable(keys: [
      Settings.backdropUI,
      Settings.showGuide,
      Settings.showBackdropGuide,
    ]);
    backdropUIListenable = _settingsBox.listenable(keys: [Settings.backdropUI]);
    compactBackdropListenable =
        _settingsBox.listenable(keys: [Settings.compactBackdrop]);
    swipeablePageDragWidthRatioListenable = _settingsBox.listenable(
        keys: [Settings.backdropUI, Settings.swipeablePageDragWidthRatio]);
    frontLayerDragHeightRatioListenable =
        _settingsBox.listenable(keys: [Settings.frontLayerDragHeightRatio]);
    backLayerDragHeightRatioListenable =
        _settingsBox.listenable(keys: [Settings.backLayerDragHeightRatio]);

    _drawerDragRatio = drawerEdgeDragWidthRatio.obs;

    isReady.value = true;
    await checkDarkMode();

    debugPrint('读取设置数据成功');
  }

  @override
  void onClose() async {
    await _darkModeSubscription.cancel();
    await _settingsBox.close();
    isReady.value = false;

    super.onClose();
  }
}
