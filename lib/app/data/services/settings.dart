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
import '../../utils/extensions.dart';
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

  static const double minPostFontSize = 10.0;

  static const double maxPostFontSize = 30.0;

  static const double defaultPostHeaderFontSize = 12.0;

  static const double defaultPostContentFontSize = 14.0;

  static final int minFontWeight = FontWeight.values.first.toInt();

  static final int maxFontWeight = FontWeight.values.last.toInt();

  static final int defaultFontWeight = FontWeight.normal.toInt();

  static const double minLineHeight = 1.0;

  static const double maxLineHeight = 3.0;

  static const double defaultLineHeight = 1.2;

  static const double minLetterSpacing = -3.0;

  static const double maxLetterSpacing = 30.0;

  static const double defaultLetterSpacing = 0.25;

  static SettingsService get to => Get.find<SettingsService>();

  static late final bool isRestoreForumPage;

  static late final bool isFixMissingFont;

  static late final bool isShowGuide;

  static late final bool isShowBottomBar;

  static late final bool isBackdropUI;

  static late final RxBool _isAutoHideAppBar;

  static bool get isSwipeablePage => isShowBottomBar || isBackdropUI;

  static bool get isAutoHideAppBar => _isAutoHideAppBar.value;

  late final Box _settingsBox;

  final RxBool hasBeenDarkMode = false.obs;

  late final RxBool _isAutoHideBottomBar;

  late final RxDouble _drawerDragRatio;

  late final RxBool _isCompactTabAndForumList;

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

  bool get fixMissingFont => _settingsBox.get(Settings.fixMissingFont,
      defaultValue: GetPlatform.isIOS);

  set fixMissingFont(bool fixMissingFont) =>
      _settingsBox.put(Settings.fixMissingFont, fixMissingFont);

  bool get showGuide =>
      !SettingsService.isBackdropUI &&
      _settingsBox.get(Settings.showGuide, defaultValue: true);

  bool get rawShowGuide =>
      _settingsBox.get(Settings.showGuide, defaultValue: true);

  set showGuide(bool showGuide) =>
      _settingsBox.put(Settings.showGuide, showGuide);

  bool get showBackdropGuide =>
      SettingsService.isBackdropUI &&
      _settingsBox.get(Settings.showBackdropGuide, defaultValue: true);

  bool get rawShowBackdropGuide =>
      _settingsBox.get(Settings.showBackdropGuide, defaultValue: true);

  set showBackdropGuide(bool showBackdropGuide) =>
      _settingsBox.put(Settings.showBackdropGuide, showBackdropGuide);

  bool get shouldShowGuide => showBackdropGuide || showGuide;

  bool get showBottomBar =>
      _settingsBox.get(Settings.showBottomBar, defaultValue: GetPlatform.isIOS);

  set showBottomBar(bool showBottomBar) =>
      _settingsBox.put(Settings.showBottomBar, showBottomBar);

  bool get autoHideBottomBar =>
      _settingsBox.get(Settings.autoHideBottomBar, defaultValue: true);

  set autoHideBottomBar(bool autoHideBottomBar) {
    _settingsBox.put(Settings.autoHideBottomBar, autoHideBottomBar);
    _isAutoHideBottomBar.value = autoHideBottomBar;
  }

  bool get isAutoHideBottomBar => _isAutoHideBottomBar.value;

  bool get backdropUI =>
      _settingsBox.get(Settings.backdropUI, defaultValue: false);

  set backdropUI(bool backdropUi) =>
      _settingsBox.put(Settings.backdropUI, backdropUi);

  double get frontLayerDragHeightRatio =>
      (_settingsBox.get(Settings.frontLayerDragHeightRatio, defaultValue: 0.20)
              as double)
          .clamp(0.0, 1.0);

  set frontLayerDragHeightRatio(double ratio) => _settingsBox.put(
      Settings.frontLayerDragHeightRatio, ratio.clamp(0.0, 1.0));

  double get backLayerDragHeightRatio =>
      (_settingsBox.get(Settings.backLayerDragHeightRatio, defaultValue: 0.10)
              as double)
          .clamp(0.0, 1.0);

  set backLayerDragHeightRatio(double ratio) => _settingsBox.put(
      Settings.backLayerDragHeightRatio, ratio.clamp(0.0, 1.0));

  bool get autoHideAppBar =>
      _settingsBox.get(Settings.autoHideAppBar, defaultValue: false);

  set autoHideAppBar(bool autoHideAppBar) {
    _settingsBox.put(Settings.autoHideAppBar, autoHideAppBar);
    _isAutoHideAppBar.value = autoHideAppBar;
  }

  bool get hideFloatingButton =>
      _settingsBox.get(Settings.hideFloatingButton, defaultValue: false);

  set hideFloatingButton(bool hideFloatingButton) =>
      _settingsBox.put(Settings.hideFloatingButton, hideFloatingButton);

  bool get autoHideFloatingButton =>
      _settingsBox.get(Settings.autoHideFloatingButton, defaultValue: false);

  set autoHideFloatingButton(bool autoHideFloatingButton) =>
      _settingsBox.put(Settings.autoHideFloatingButton, autoHideFloatingButton);

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

  double get drawerDragRatio => _drawerDragRatio.value;

  double get swipeablePageDragWidthRatio =>
      (_settingsBox.get(Settings.swipeablePageDragWidthRatio,
              defaultValue: 0.25) as double)
          .clamp(0.0, 1.0);

  set swipeablePageDragWidthRatio(double ratio) => _settingsBox.put(
      Settings.swipeablePageDragWidthRatio, ratio.clamp(0.0, 1.0));

  bool get compactTabAndForumList =>
      _settingsBox.get(Settings.compactTabAndForumList, defaultValue: false);

  set compactTabAndForumList(bool isCompact) {
    _settingsBox.put(Settings.compactTabAndForumList, isCompact);
    _isCompactTabAndForumList.value = isCompact;
  }

  bool get isCompactTabAndForumList => _isCompactTabAndForumList.value;

  double get postHeaderFontSize =>
      (_settingsBox.get(Settings.postHeaderFontSize,
              defaultValue: defaultPostHeaderFontSize) as double)
          .roundToDouble()
          .clamp(minPostFontSize, maxPostFontSize);

  set postHeaderFontSize(double fontSize) => _settingsBox.put(
      Settings.postHeaderFontSize,
      fontSize.roundToDouble().clamp(minPostFontSize, maxPostFontSize));

  int get postHeaderFontWeight =>
      (_settingsBox.get(Settings.postHeaderFontWeight,
              defaultValue: defaultFontWeight) as int)
          .clamp(minFontWeight, maxFontWeight);

  set postHeaderFontWeight(int fontWeight) => _settingsBox.put(
      Settings.postHeaderFontWeight,
      fontWeight.clamp(minFontWeight, maxFontWeight));

  double get postHeaderLineHeight =>
      (_settingsBox.get(Settings.postHeaderLineHeight,
              defaultValue: defaultLineHeight) as double)
          .clamp(minLineHeight, maxLineHeight);

  set postHeaderLineHeight(double height) => _settingsBox.put(
      Settings.postHeaderLineHeight,
      height.clamp(minLineHeight, maxLineHeight));

  double get postHeaderDefaultLineHeight =>
      postHeaderLineHeight < defaultLineHeight
          ? postHeaderLineHeight
          : defaultLineHeight;

  double get postHeaderLetterSpacing =>
      (_settingsBox.get(Settings.postHeaderLetterSpacing,
              defaultValue: defaultLetterSpacing) as double)
          .clamp(minLetterSpacing, maxLetterSpacing);

  set postHeaderLetterSpacing(double letterSpacing) => _settingsBox.put(
      Settings.postHeaderLetterSpacing,
      letterSpacing.clamp(minLetterSpacing, maxLetterSpacing));

  double get postContentFontSize =>
      (_settingsBox.get(Settings.postContentFontSize,
              defaultValue: defaultPostContentFontSize) as double)
          .roundToDouble()
          .clamp(minPostFontSize, maxPostFontSize);

  set postContentFontSize(double fontSize) => _settingsBox.put(
      Settings.postContentFontSize,
      fontSize.roundToDouble().clamp(minPostFontSize, maxPostFontSize));

  int get postContentFontWeight =>
      (_settingsBox.get(Settings.postContentFontWeight,
              defaultValue: defaultFontWeight) as int)
          .clamp(minFontWeight, maxFontWeight);

  set postContentFontWeight(int fontWeight) => _settingsBox.put(
      Settings.postContentFontWeight,
      fontWeight.clamp(minFontWeight, maxFontWeight));

  double get postContentLineHeight =>
      (_settingsBox.get(Settings.postContentLineHeight,
              defaultValue: defaultLineHeight) as double)
          .clamp(minLineHeight, maxLineHeight);

  set postContentLineHeight(double height) => _settingsBox.put(
      Settings.postContentLineHeight,
      height.clamp(minLineHeight, maxLineHeight));

  double get postContentLetterSpacing =>
      (_settingsBox.get(Settings.postContentLetterSpacing,
              defaultValue: defaultLetterSpacing) as double)
          .clamp(minLetterSpacing, maxLetterSpacing);

  set postContentLetterSpacing(double letterSpacing) => _settingsBox.put(
      Settings.postContentLetterSpacing,
      letterSpacing.clamp(minLetterSpacing, maxLetterSpacing));

  late final ValueListenable<Box> isDarkModeListenable;

  late final ValueListenable<Box> isRestoreTabsListenable;

  late final ValueListenable<Box> initialForumListenable;

  late final ValueListenable<Box> showImageListenable;

  late final ValueListenable<Box> isWatermarkListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePageListenable;

  late final ValueListenable<Box> isJumpToLastBrowsePositionListenable;

  late final ValueListenable<Box> isAfterPostRefreshListenable;

  late final ValueListenable<Box> dismissibleTabListenable;

  late final ValueListenable<Box> feedIdListenable;

  late final ValueListenable<Box> saveImagePathListenable;

  late final ValueListenable<Box> addBlueIslandEmoticonsListenable;

  late final ValueListenable<Box> restoreForumPageListenable;

  late final ValueListenable<Box> imageDisposeDistanceListenable;

  late final ValueListenable<Box> fixedImageDisposeRatioListenable;

  late final ValueListenable<Box> fixMissingFontListenable;

  late final ValueListenable<Box> showGuideListenable;

  late final ValueListenable<Box> showBottomBarListenable;

  late final ValueListenable<Box> autoHideBottomBarListenable;

  late final ValueListenable<Box> backdropUIListenable;

  late final ValueListenable<Box> frontLayerDragHeightRatioListenable;

  late final ValueListenable<Box> backLayerDragHeightRatioListenable;

  late final ValueListenable<Box> autoHideAppBarListenable;

  late final ValueListenable<Box> hideFloatingButtonListenable;

  late final ValueListenable<Box> autoHideFloatingButtonListenable;

  late final ValueListenable<Box> drawerEdgeDragWidthRatioListenable;

  late final ValueListenable<Box> swipeablePageDragWidthRatioListenable;

  late final ValueListenable<Box> compactTabAndForumListListenable;

  late final StreamSubscription<BoxEvent> _darkModeSubscription;

  static Future<void> getSettings() async {
    final box = await Hive.openBox(HiveBoxName.settings);

    ImageService.savePath = box.get(Settings.saveImagePath, defaultValue: null);
    // 是否修复字体，结果保存在`fixMissingFont`
    isFixMissingFont =
        box.get(Settings.fixMissingFont, defaultValue: GetPlatform.isIOS);
    isRestoreForumPage =
        box.get(Settings.restoreForumPage, defaultValue: false);
    isShowBottomBar =
        box.get(Settings.showBottomBar, defaultValue: GetPlatform.isIOS);
    isBackdropUI = box.get(Settings.backdropUI, defaultValue: false);
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

  TextStyle postHeaderTextStyle([TextStyle? textStyle]) => TextStyle(
        fontSize: postHeaderFontSize,
        fontWeight: FontWeightExtension.fromInt(postHeaderFontWeight),
        height: postHeaderDefaultLineHeight,
        letterSpacing: postHeaderLetterSpacing,
      ).merge(textStyle);

  TextStyle postContentTextStyle([TextStyle? textStyle]) => TextStyle(
        fontSize: postContentFontSize,
        fontWeight: FontWeightExtension.fromInt(postContentFontWeight),
        height: postContentLineHeight,
        letterSpacing: postContentLetterSpacing,
      ).merge(textStyle);

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

    isDarkModeListenable = _settingsBox.listenable(keys: [Settings.isDarkMode]);
    isRestoreTabsListenable =
        _settingsBox.listenable(keys: [Settings.isRestoreTabs]);
    initialForumListenable = _settingsBox
        .listenable(keys: [Settings.isRestoreTabs, Settings.initialForum]);
    showImageListenable = _settingsBox.listenable(keys: [Settings.showImage]);
    isWatermarkListenable =
        _settingsBox.listenable(keys: [Settings.isWatermark]);
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
    showBottomBarListenable =
        _settingsBox.listenable(keys: [Settings.showBottomBar]);
    autoHideBottomBarListenable =
        _settingsBox.listenable(keys: [Settings.autoHideBottomBar]);
    backdropUIListenable = _settingsBox.listenable(keys: [Settings.backdropUI]);
    frontLayerDragHeightRatioListenable =
        _settingsBox.listenable(keys: [Settings.frontLayerDragHeightRatio]);
    backLayerDragHeightRatioListenable =
        _settingsBox.listenable(keys: [Settings.backLayerDragHeightRatio]);
    autoHideAppBarListenable =
        _settingsBox.listenable(keys: [Settings.autoHideAppBar]);
    hideFloatingButtonListenable =
        _settingsBox.listenable(keys: [Settings.hideFloatingButton]);
    autoHideFloatingButtonListenable =
        _settingsBox.listenable(keys: [Settings.autoHideFloatingButton]);
    drawerEdgeDragWidthRatioListenable = _settingsBox.listenable(
        keys: [Settings.showBottomBar, Settings.drawerEdgeDragWidthRatio]);
    swipeablePageDragWidthRatioListenable = _settingsBox.listenable(keys: [
      Settings.showBottomBar,
      Settings.backdropUI,
      Settings.swipeablePageDragWidthRatio,
    ]);
    compactTabAndForumListListenable =
        _settingsBox.listenable(keys: [Settings.compactTabAndForumList]);

    _isAutoHideBottomBar = autoHideBottomBar.obs;
    _isAutoHideAppBar = autoHideAppBar.obs;
    _drawerDragRatio = drawerEdgeDragWidthRatio.obs;
    _isCompactTabAndForumList = compactTabAndForumList.obs;

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
