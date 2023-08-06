import 'dart:async';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../utils/backup.dart';
import '../../utils/extensions.dart';
import '../models/forum.dart';
import '../models/hive.dart';
import '../models/settings.dart';
import 'image.dart';
import 'user.dart';

final ForumData defaultForum = ForumData(
    id: 1,
    name: '综合线',
    displayName: '综合线',
    message: '主时间线',
    maxPage: 20,
    isTimeline: true);

/// 设置服务
class SettingsService extends GetxService {
  static const int defaultConnectionTimeout = 15;

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

  static final SettingsService to = Get.find<SettingsService>();

  static late final bool isAllowTransparentSystemNavigationBar;

  static late Duration connectionTimeoutSecond;

  static late final bool isRestoreForumPage;

  static late final bool isFixMissingFont;

  static bool shouldShowGuide = false;

  static late final bool isShowGuide;

  late final Box _settingsBox;

  final RxBool isDarkModeRx = false.obs;

  late final RxBool _useDrawerAndEndDrawer;

  late final RxBool _showBottomBar;

  late final RxBool _autoHideBottomBar;

  late final RxInt _endDrawerContent;

  late final RxBool _autoHideAppBar;

  late final RxDouble _drawerEdgeDragWidthRatio;

  late final RxBool _compactTabAndForumList;

  late final RxInt _showLatestPostTimeInFeed;

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
      _settingsBox.put(Settings.initialForum, forum.copy());

  bool get showImage =>
      _settingsBox.get(Settings.showImage, defaultValue: true);

  set showImage(bool showImage) =>
      _settingsBox.put(Settings.showImage, showImage);

  bool get showLargeImageInPost =>
      _settingsBox.get(Settings.showLargeImageInPost, defaultValue: false);

  set showLargeImageInPost(bool showLargeImageInPost) =>
      _settingsBox.put(Settings.showLargeImageInPost, showLargeImageInPost);

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

  /// 0是跳转位置，1是只跳转页数，2是不跳转
  int get jumpToLastBrowseSetting =>
      isJumpToLastBrowsePage ? (isJumpToLastBrowsePosition ? 0 : 1) : 2;

  set jumpToLastBrowseSetting(int jumpToLastBrowseSetting) {
    switch (jumpToLastBrowseSetting.clamp(0, 2)) {
      case 0:
        isJumpToLastBrowsePage = true;
        isJumpToLastBrowsePosition = true;
        break;
      case 1:
        isJumpToLastBrowsePage = true;
        isJumpToLastBrowsePosition = false;
        break;
      case 2:
        isJumpToLastBrowsePage = false;
        isJumpToLastBrowsePosition = false;
        break;
    }
  }

  bool get isAfterPostRefresh =>
      _settingsBox.get(Settings.isAfterPostRefresh, defaultValue: true);

  set isAfterPostRefresh(bool isAfterPostRefresh) =>
      _settingsBox.put(Settings.isAfterPostRefresh, isAfterPostRefresh);

  bool get dismissibleTab =>
      _settingsBox.get(Settings.dismissibleTab, defaultValue: false);

  set dismissibleTab(bool dismissibleTab) =>
      _settingsBox.put(Settings.dismissibleTab, dismissibleTab);

  bool get selectCookieBeforePost =>
      _settingsBox.get(Settings.selectCookieBeforePost, defaultValue: false);

  set selectCookieBeforePost(bool selectCookieBeforePost) =>
      _settingsBox.put(Settings.selectCookieBeforePost, selectCookieBeforePost);

  bool get forbidDuplicatedPosts =>
      _settingsBox.get(Settings.forbidDuplicatedPosts, defaultValue: true);

  set forbidDuplicatedPosts(bool forbidDuplicatedPosts) =>
      _settingsBox.put(Settings.forbidDuplicatedPosts, forbidDuplicatedPosts);

  String get feedId => _settingsBox.get(Settings.feedId);

  set feedId(String feedId) => _settingsBox.put(Settings.feedId, feedId);

  bool get useHtmlFeed => UserService.to.hasBrowseCookie
      ? _settingsBox.get(Settings.useHtmlFeed, defaultValue: false)
      : false;

  set useHtmlFeed(bool useHtmlFeed) {
    if (UserService.to.hasBrowseCookie) {
      _settingsBox.put(Settings.useHtmlFeed, useHtmlFeed);
    }
  }

  bool get useBackupApi =>
      _settingsBox.get(Settings.useBackupApi, defaultValue: false);

  set useBackupApi(bool useBackupApi) =>
      _settingsBox.put(Settings.useBackupApi, useBackupApi);

  int get connectionTimeout => max(
      _settingsBox.get(Settings.connectionTimeout,
          defaultValue: defaultConnectionTimeout),
      1);

  set connectionTimeout(int timeout) {
    timeout = max(timeout, 1);
    _settingsBox.put(Settings.connectionTimeout, timeout);
    connectionTimeoutSecond = Duration(seconds: timeout);
  }

  String? get saveImagePath => !(GetPlatform.isIOS || GetPlatform.isMacOS)
      ? _settingsBox.get(Settings.saveImagePath, defaultValue: null)
      : null;

  set saveImagePath(String? directory) {
    if (!(GetPlatform.isIOS || GetPlatform.isMacOS)) {
      _settingsBox.put(Settings.saveImagePath, directory);
      ImageService.savePath = directory;
    }
  }

  int get cacheImageCount =>
      _settingsBox.get(Settings.cacheImageCount, defaultValue: 200);

  set cacheImageCount(int count) =>
      _settingsBox.put(Settings.cacheImageCount, count);

  bool get followPlatformBrightness => (GetPlatform.isMobile ||
          GetPlatform.isMacOS)
      ? _settingsBox.get(Settings.followPlatformBrightness, defaultValue: false)
      : false;

  set followPlatformBrightness(bool followPlatformBrightness) {
    if (GetPlatform.isMobile || GetPlatform.isMacOS) {
      _settingsBox.put(
          Settings.followPlatformBrightness, followPlatformBrightness);
    }
  }

  bool get addBlueIslandEmoticons =>
      _settingsBox.get(Settings.addBlueIslandEmoticons, defaultValue: true);

  set addBlueIslandEmoticons(bool addBlueIslandEmoticons) =>
      _settingsBox.put(Settings.addBlueIslandEmoticons, addBlueIslandEmoticons);

  bool get restoreForumPage =>
      _settingsBox.get(Settings.restoreForumPage, defaultValue: false);

  set restoreForumPage(bool restoreForumPage) =>
      _settingsBox.put(Settings.restoreForumPage, restoreForumPage);

  bool get addDeleteFeedInThread =>
      _settingsBox.get(Settings.addDeleteFeedInThread, defaultValue: false);

  set addDeleteFeedInThread(bool addDeleteFeedInThread) =>
      _settingsBox.put(Settings.addDeleteFeedInThread, addDeleteFeedInThread);

  bool get longPressButtonToOpenNewTab => _settingsBox
      .get(Settings.longPressButtonToOpenNewTab, defaultValue: false);

  set longPressButtonToOpenNewTab(bool longPressButtonToOpenNewTab) =>
      _settingsBox.put(
          Settings.longPressButtonToOpenNewTab, longPressButtonToOpenNewTab);

  int get maxPagesEachTab =>
      max(_settingsBox.get(Settings.maxPagesEachTab, defaultValue: 0), 0);

  set maxPagesEachTab(int maxPages) =>
      _settingsBox.put(Settings.maxPagesEachTab, max(maxPages, 0));

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

  bool get rawShowGuide =>
      _settingsBox.get(Settings.showGuide, defaultValue: true);

  bool get showGuide =>
      rawShowGuide ||
      showDrawerAndEndDrawerGuide ||
      showBottomBarGuide ||
      showOnlyEndDrawerGuide;

  set showGuide(bool showGuide) =>
      _settingsBox.put(Settings.showGuide, showGuide);

  bool get showDrawerAndEndDrawerGuide =>
      useDrawerAndEndDrawer &&
      _settingsBox.get(Settings.showDrawerAndEndDrawerGuide,
          defaultValue: true);

  set showDrawerAndEndDrawerGuide(bool showDrawerAndEndDrawerGuide) =>
      _settingsBox.put(
          Settings.showDrawerAndEndDrawerGuide, showDrawerAndEndDrawerGuide);

  bool get showOnlyEndDrawerGuide =>
      !useDrawerAndEndDrawer &&
      endDrawerSetting > 0 &&
      _settingsBox.get(Settings.showOnlyEndDrawerGuide, defaultValue: true);

  set showOnlyEndDrawerGuide(bool showOnlyEndDrawerGuide) =>
      _settingsBox.put(Settings.showOnlyEndDrawerGuide, showOnlyEndDrawerGuide);

  bool get showBottomBarGuide =>
      bottomBarSetting != 2 &&
      endDrawerSetting == 0 &&
      _settingsBox.get(Settings.showBottomBarGuide, defaultValue: true);

  set showBottomBarGuide(bool showBottomBarGuide) =>
      _settingsBox.put(Settings.showBottomBarGuide, showBottomBarGuide);

  bool get useDrawerAndEndDrawer => !GetPlatform.isIOS
      ? _settingsBox.get(Settings.useDrawerAndEndDrawer, defaultValue: false)
      : false;

  set useDrawerAndEndDrawer(bool useDrawerAndEndDrawer) {
    if (!GetPlatform.isIOS) {
      _settingsBox.put(Settings.useDrawerAndEndDrawer, useDrawerAndEndDrawer);
      _useDrawerAndEndDrawer.value = useDrawerAndEndDrawer;
    }
  }

  bool get useDrawerAndEndDrawerRx => _useDrawerAndEndDrawer.value;

  bool get isSwipeablePageRx => !useDrawerAndEndDrawerRx;

  bool get showBottomBar =>
      _settingsBox.get(Settings.showBottomBar, defaultValue: true);

  set showBottomBar(bool showBottomBar) {
    _settingsBox.put(Settings.showBottomBar, showBottomBar);
    _showBottomBar.value = showBottomBar;
  }

  bool get showBottomBarRx => _showBottomBar.value;

  bool get autoHideBottomBar =>
      _settingsBox.get(Settings.autoHideBottomBar, defaultValue: true);

  set autoHideBottomBar(bool autoHideBottomBar) {
    _settingsBox.put(Settings.autoHideBottomBar, autoHideBottomBar);
    _autoHideBottomBar.value = autoHideBottomBar;
  }

  bool get autoHideBottomBarRx => _autoHideBottomBar.value;

  /// 0是向下滑动时隐藏底边栏，1是始终显示底边栏，2是不显示底边栏
  int get bottomBarSetting => !useDrawerAndEndDrawer
      ? (showBottomBar ? (autoHideBottomBar ? 0 : 1) : 2)
      : 2;

  set bottomBarSetting(int bottomBarSetting) {
    if (!useDrawerAndEndDrawer) {
      switch (bottomBarSetting.clamp(0, 2)) {
        case 0:
          showBottomBar = true;
          autoHideBottomBar = true;
          break;
        case 1:
          showBottomBar = true;
          autoHideBottomBar = false;
          break;
        case 2:
          showBottomBar = false;
          autoHideBottomBar = false;
          break;
      }
    }
  }

  /// 0是向下滑动时隐藏底边栏，1是始终显示底边栏，2是不显示底边栏
  int get bottomBarSettingRx => !useDrawerAndEndDrawerRx
      ? (showBottomBarRx ? (autoHideBottomBarRx ? 0 : 1) : 2)
      : 2;

  bool get hasBottomBar => bottomBarSetting < 2;

  bool get hasBottomBarRx => bottomBarSettingRx < 2;

  bool get bottomBarHasTabOrForumListButtonRx =>
      hasBottomBarRx && endDrawerSettingRx < 3;

  bool get bottomBarHasSingleTabOrForumListButtonRx =>
      hasBottomBarRx && (endDrawerSettingRx == 1 || endDrawerSettingRx == 2);

  /// 0是不用侧边栏，1是版块侧边栏，2是标签页侧边栏，3是版块/标签页侧边栏
  int get endDrawerContent =>
      (_settingsBox.get(Settings.endDrawerContent, defaultValue: 0) as int)
          .clamp(0, 3);

  set endDrawerContent(int endDrawerContent) {
    final value = endDrawerContent.clamp(0, 3);
    _settingsBox.put(Settings.endDrawerContent, value);
    _endDrawerContent.value = value;
  }

  /// 0是不用侧边栏，1是版块侧边栏，2是标签页侧边栏，3是版块/标签页侧边栏
  int get endDrawerSetting => useDrawerAndEndDrawer
      ? endDrawerContent.clamp(1, 2)
      : (bottomBarSetting < 2 ? endDrawerContent : 3);

  set endDrawerSetting(int endDrawerSetting) =>
      endDrawerContent = useDrawerAndEndDrawer
          ? endDrawerSetting.clamp(1, 2)
          : (bottomBarSetting < 2 ? endDrawerSetting : 3);

  /// 0是不用侧边栏，1是版块侧边栏，2是标签页侧边栏，3是标签页/版块侧边栏
  int get endDrawerSettingRx => useDrawerAndEndDrawerRx
      ? _endDrawerContent.value.clamp(1, 2)
      : (bottomBarSettingRx < 2 ? _endDrawerContent.value.clamp(0, 3) : 3);

  bool get endDrawerHasOnlyTabAndForumList =>
      !useDrawerAndEndDrawer && bottomBarSetting == 2;

  bool get hasDrawerRx => useDrawerAndEndDrawerRx;

  bool get hasEndDrawerRx => endDrawerSettingRx > 0;

  bool get hasDrawerOrEndDrawerRx => hasDrawerRx || hasEndDrawerRx;

  bool get autoHideAppBar =>
      _settingsBox.get(Settings.autoHideAppBar, defaultValue: false);

  set autoHideAppBar(bool autoHideAppBar) {
    _settingsBox.put(Settings.autoHideAppBar, autoHideAppBar);
    _autoHideAppBar.value = autoHideAppBar;
  }

  bool get autoHideAppBarRx => _autoHideAppBar.value;

  bool get hideFloatingButton =>
      _settingsBox.get(Settings.hideFloatingButton, defaultValue: false);

  set hideFloatingButton(bool hideFloatingButton) =>
      _settingsBox.put(Settings.hideFloatingButton, hideFloatingButton);

  bool get autoHideFloatingButton =>
      _settingsBox.get(Settings.autoHideFloatingButton, defaultValue: false);

  set autoHideFloatingButton(bool autoHideFloatingButton) =>
      _settingsBox.put(Settings.autoHideFloatingButton, autoHideFloatingButton);

  /// 0是始终显示悬浮球，1是隐藏悬浮球，2是向下滑动时隐藏悬浮球
  int get floatingButtonSetting => !hasBottomBar
      ? (hideFloatingButton ? 1 : (autoHideFloatingButton ? 2 : 0))
      : 1;

  set floatingButtonSetting(int floatingButtonSetting) {
    if (!hasBottomBar) {
      switch (floatingButtonSetting.clamp(0, 2)) {
        case 0:
          hideFloatingButton = false;
          autoHideFloatingButton = false;
          break;
        case 1:
          hideFloatingButton = true;
          autoHideFloatingButton = false;
          break;
        case 2:
          hideFloatingButton = false;
          autoHideFloatingButton = true;
          break;
      }
    }
  }

  /// 不包含设置里隐藏悬浮球的情况
  bool get hasFloatingButton => !hasBottomBar;

  double get drawerEdgeDragWidthRatio =>
      (_settingsBox.get(Settings.drawerEdgeDragWidthRatio, defaultValue: 0.25)
              as double)
          .clamp(minDrawerEdgeDragWidthRatio, maxDrawerEdgeDragWidthRatio);

  set drawerEdgeDragWidthRatio(double ratio) {
    ratio =
        ratio.clamp(minDrawerEdgeDragWidthRatio, maxDrawerEdgeDragWidthRatio);
    _settingsBox.put(Settings.drawerEdgeDragWidthRatio, ratio);
    _drawerEdgeDragWidthRatio.value = ratio;
  }

  double get drawerEdgeDragWidthRatioRx => _drawerEdgeDragWidthRatio.value;

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
    _compactTabAndForumList.value = isCompact;
  }

  bool get transparentSystemNavigationBar =>
      isAllowTransparentSystemNavigationBar
          ? _settingsBox.get(Settings.transparentSystemNavigationBar,
              defaultValue: true)
          : false;

  set transparentSystemNavigationBar(bool transparentSystemNavigationBar) =>
      _settingsBox.put(Settings.transparentSystemNavigationBar,
          transparentSystemNavigationBar);

  bool get compactTabAndForumListRx => _compactTabAndForumList.value;

  bool get showPoCookieTag =>
      _settingsBox.get(Settings.showPoCookieTag, defaultValue: false);

  set showPoCookieTag(bool showPoCookieTag) =>
      _settingsBox.put(Settings.showPoCookieTag, showPoCookieTag);

  Color get poCookieColor =>
      Color(_settingsBox.get(Settings.poCookieColor, defaultValue: 0xff0097a7));

  set poCookieColor(Color color) =>
      _settingsBox.put(Settings.poCookieColor, color.value);

  bool get showUserCookieNote =>
      _settingsBox.get(Settings.showUserCookieNote, defaultValue: false);

  set showUserCookieNote(bool showUserCookieNote) =>
      _settingsBox.put(Settings.showUserCookieNote, showUserCookieNote);

  bool get showUserCookieColor =>
      _settingsBox.get(Settings.showUserCookieColor, defaultValue: true);

  set showUserCookieColor(bool showUserCookieColor) =>
      _settingsBox.put(Settings.showUserCookieColor, showUserCookieColor);

  bool get showRelativeTime =>
      _settingsBox.get(Settings.showRelativeTime, defaultValue: false);

  set showRelativeTime(bool showRelativeTime) =>
      _settingsBox.put(Settings.showRelativeTime, showRelativeTime);

  /// 0是不显示，1是显示具体时间，2是显示相对时间
  int get showLatestPostTimeInFeed =>
      (_settingsBox.get(Settings.showLatestPostTimeInFeed, defaultValue: 0)
              as int)
          .clamp(0, 2);

  set showLatestPostTimeInFeed(int mode) {
    mode = mode.clamp(0, 2);
    _settingsBox.put(Settings.showLatestPostTimeInFeed, mode);
    _showLatestPostTimeInFeed.value = mode;
  }

  bool get isNotShowLatestPostTimeInFeed => showLatestPostTimeInFeed == 0;

  bool get isShowLatestAbsolutePostTimeInFeed => showLatestPostTimeInFeed == 1;

  bool get isShowLatestRelativePostTimeInFeed => showLatestPostTimeInFeed == 2;

  int get showLatestPostTimeInFeedRx => _showLatestPostTimeInFeed.value;

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

  late final ValueListenable<Box> showLargeImageInPostListenable;

  late final ValueListenable<Box> isWatermarkListenable;

  late final ValueListenable<Box> jumpToLastBrowseSettingListenable;

  late final ValueListenable<Box> isAfterPostRefreshListenable;

  late final ValueListenable<Box> dismissibleTabListenable;

  late final ValueListenable<Box> selectCookieBeforePostListenable;

  late final ValueListenable<Box> forbidDuplicatedPostsListenable;

  late final ValueListenable<Box> feedIdListenable;

  late final ValueListenable<Box> useHtmlFeedListenable;

  late final ValueListenable<Box> useBackupApiListenable;

  late final ValueListenable<Box> connectionTimeoutListenable;

  late final ValueListenable<Box> saveImagePathListenable;

  late final ValueListenable<Box> cacheImageCountListenable;

  late final ValueListenable<Box> followPlatformBrightnessListenable;

  late final ValueListenable<Box> addBlueIslandEmoticonsListenable;

  late final ValueListenable<Box> restoreForumPageListenable;

  late final ValueListenable<Box> addDeleteFeedInThreadListenable;

  late final ValueListenable<Box> longPressButtonToOpenNewTabListenable;

  late final ValueListenable<Box> maxPagesEachTabListenable;

  late final ValueListenable<Box> imageDisposeDistanceListenable;

  late final ValueListenable<Box> fixedImageDisposeRatioListenable;

  late final ValueListenable<Box> fixMissingFontListenable;

  late final ValueListenable<Box> showGuideListenable;

  late final ValueListenable<Box> useDrawerAndEndDrawerListenable;

  late final ValueListenable<Box> bottomBarSettingListenable;

  late final ValueListenable<Box> endDrawerSettingListenable;

  late final ValueListenable<Box> autoHideAppBarListenable;

  late final ValueListenable<Box> floatingButtonSettingListenable;

  late final ValueListenable<Box> drawerEdgeDragWidthRatioListenable;

  late final ValueListenable<Box> swipeablePageDragWidthRatioListenable;

  late final ValueListenable<Box> compactTabAndForumListListenable;

  late final ValueListenable<Box> transparentSystemNavigationBarListListenable;

  late final ValueListenable<Box> showPoCookieTagListenable;

  late final ValueListenable<Box> poCookieColorListenable;

  late final ValueListenable<Box> showUserCookieNoteListenable;

  late final ValueListenable<Box> showUserCookieColorListenable;

  late final ValueListenable<Box> showRelativeTimeListenable;

  late final ValueListenable<Box> showLatestPostTimeInFeedListenable;

  late final StreamSubscription<BoxEvent> _darkModeSubscription;

  late final StreamSubscription<BoxEvent>
      _transparentSystemNavigationBarSubscription;

  static Future<void> getSettings() async {
    final box = await Hive.openBox(HiveBoxName.settings);

    ImageService.savePath = !(GetPlatform.isIOS || GetPlatform.isMacOS)
        ? box.get(Settings.saveImagePath, defaultValue: null)
        : null;
    connectionTimeoutSecond = Duration(
        seconds: max(
            box.get(Settings.connectionTimeout,
                defaultValue: defaultConnectionTimeout),
            1));
    isRestoreForumPage =
        box.get(Settings.restoreForumPage, defaultValue: false);
    // 是否修复字体
    isFixMissingFont =
        box.get(Settings.fixMissingFont, defaultValue: GetPlatform.isIOS);

    // 兼容旧版本
    if (!GetPlatform.isIOS &&
        !box.containsKey(Settings.useDrawerAndEndDrawer)) {
      if (box.get(Settings.showBottomBar, defaultValue: true)) {
        await box.put(Settings.useDrawerAndEndDrawer, false);
      } else {
        await box.put(Settings.useDrawerAndEndDrawer, true);
      }
    }
  }

  Future<void> _updateTransparentSystemNavigationBar() async {
    if (GetPlatform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 30) {
      isAllowTransparentSystemNavigationBar = true;
    } else {
      isAllowTransparentSystemNavigationBar = false;
      transparentSystemNavigationBar = false;
    }
  }

  void _setDarkModeWithPlatformBrightness() => isDarkMode =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;

  void _setSystemUIOverlayStyle() =>
      SystemChrome.setSystemUIOverlayStyle((isDarkModeRx.value
              ? (transparentSystemNavigationBar
                  ? const SystemUiOverlayStyle(
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarDividerColor: Colors.transparent,
                      systemNavigationBarIconBrightness: Brightness.light,
                      systemNavigationBarContrastEnforced: false)
                  : SystemUiOverlayStyle.light)
              : (transparentSystemNavigationBar
                  ? const SystemUiOverlayStyle(
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarDividerColor: Colors.transparent,
                      systemNavigationBarIconBrightness: Brightness.dark,
                      systemNavigationBarContrastEnforced: false)
                  : SystemUiOverlayStyle.dark))
          .copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemStatusBarContrastEnforced: false));

  void updateSaveImagePath() {
    if (!(GetPlatform.isIOS || GetPlatform.isMacOS) &&
        saveImagePath != ImageService.savePath) {
      saveImagePath = ImageService.savePath;
    }
  }

  Future<void> checkDarkMode() async {
    // 等待生效
    while (isDarkMode != Get.isDarkMode) {
      debugPrint('正在切换白天/黑夜模式');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    isDarkModeRx.value = Get.isDarkMode;
    _setSystemUIOverlayStyle();
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

    await _updateTransparentSystemNavigationBar();

    if (followPlatformBrightness) {
      _setDarkModeWithPlatformBrightness();
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
          () {
        WidgetsBinding.instance.handlePlatformBrightnessChanged();
        _setDarkModeWithPlatformBrightness();
      };
    }
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
    jumpToLastBrowseSettingListenable = _settingsBox.listenable(keys: [
      Settings.isJumpToLastBrowsePage,
      Settings.isJumpToLastBrowsePosition,
    ]);
    isAfterPostRefreshListenable =
        _settingsBox.listenable(keys: [Settings.isAfterPostRefresh]);
    dismissibleTabListenable =
        _settingsBox.listenable(keys: [Settings.dismissibleTab]);
    selectCookieBeforePostListenable =
        _settingsBox.listenable(keys: [Settings.selectCookieBeforePost]);
    forbidDuplicatedPostsListenable =
        _settingsBox.listenable(keys: [Settings.forbidDuplicatedPosts]);
    feedIdListenable =
        _settingsBox.listenable(keys: [Settings.feedId, Settings.useHtmlFeed]);
    useHtmlFeedListenable =
        _settingsBox.listenable(keys: [Settings.useHtmlFeed]);
    useBackupApiListenable =
        _settingsBox.listenable(keys: [Settings.useBackupApi]);
    connectionTimeoutListenable =
        _settingsBox.listenable(keys: [Settings.connectionTimeout]);
    saveImagePathListenable =
        _settingsBox.listenable(keys: [Settings.saveImagePath]);
    showLargeImageInPostListenable =
        _settingsBox.listenable(keys: [Settings.showLargeImageInPost]);
    cacheImageCountListenable =
        _settingsBox.listenable(keys: [Settings.cacheImageCount]);
    followPlatformBrightnessListenable =
        _settingsBox.listenable(keys: [Settings.followPlatformBrightness]);
    addBlueIslandEmoticonsListenable =
        _settingsBox.listenable(keys: [Settings.addBlueIslandEmoticons]);
    restoreForumPageListenable =
        _settingsBox.listenable(keys: [Settings.restoreForumPage]);
    addDeleteFeedInThreadListenable =
        _settingsBox.listenable(keys: [Settings.addDeleteFeedInThread]);
    longPressButtonToOpenNewTabListenable =
        _settingsBox.listenable(keys: [Settings.longPressButtonToOpenNewTab]);
    maxPagesEachTabListenable =
        _settingsBox.listenable(keys: [Settings.maxPagesEachTab]);
    imageDisposeDistanceListenable =
        _settingsBox.listenable(keys: [Settings.imageDisposeDistance]);
    fixedImageDisposeRatioListenable =
        _settingsBox.listenable(keys: [Settings.fixedImageDisposeRatio]);
    fixMissingFontListenable =
        _settingsBox.listenable(keys: [Settings.fixMissingFont]);
    showGuideListenable = _settingsBox.listenable(keys: [Settings.showGuide]);
    useDrawerAndEndDrawerListenable =
        _settingsBox.listenable(keys: [Settings.useDrawerAndEndDrawer]);
    bottomBarSettingListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.showBottomBar,
      Settings.autoHideBottomBar,
    ]);
    endDrawerSettingListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.showBottomBar,
      Settings.autoHideBottomBar,
      Settings.endDrawerContent,
    ]);
    autoHideAppBarListenable =
        _settingsBox.listenable(keys: [Settings.autoHideAppBar]);
    floatingButtonSettingListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.showBottomBar,
      Settings.autoHideBottomBar,
      Settings.hideFloatingButton,
      Settings.autoHideFloatingButton,
    ]);
    drawerEdgeDragWidthRatioListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.showBottomBar,
      Settings.autoHideBottomBar,
      Settings.endDrawerContent,
      Settings.drawerEdgeDragWidthRatio,
    ]);
    swipeablePageDragWidthRatioListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.swipeablePageDragWidthRatio,
    ]);
    compactTabAndForumListListenable = _settingsBox.listenable(keys: [
      Settings.useDrawerAndEndDrawer,
      Settings.showBottomBar,
      Settings.autoHideBottomBar,
      Settings.endDrawerContent,
      Settings.compactTabAndForumList,
    ]);
    transparentSystemNavigationBarListListenable = _settingsBox
        .listenable(keys: [Settings.transparentSystemNavigationBar]);
    showPoCookieTagListenable =
        _settingsBox.listenable(keys: [Settings.showPoCookieTag]);
    poCookieColorListenable =
        _settingsBox.listenable(keys: [Settings.poCookieColor]);
    showUserCookieNoteListenable =
        _settingsBox.listenable(keys: [Settings.showUserCookieNote]);
    showUserCookieColorListenable =
        _settingsBox.listenable(keys: [Settings.showUserCookieColor]);
    showRelativeTimeListenable =
        _settingsBox.listenable(keys: [Settings.showRelativeTime]);
    showLatestPostTimeInFeedListenable = _settingsBox.listenable(
        keys: [Settings.useHtmlFeed, Settings.showLatestPostTimeInFeed]);

    _useDrawerAndEndDrawer = useDrawerAndEndDrawer.obs;
    _showBottomBar = showBottomBar.obs;
    _autoHideBottomBar = autoHideBottomBar.obs;
    _endDrawerContent = endDrawerContent.obs;
    _autoHideAppBar = autoHideAppBar.obs;
    _drawerEdgeDragWidthRatio = drawerEdgeDragWidthRatio.obs;
    _compactTabAndForumList = compactTabAndForumList.obs;
    _showLatestPostTimeInFeed = showLatestPostTimeInFeed.obs;
    shouldShowGuide = showGuide;
    isShowGuide = shouldShowGuide;

    _transparentSystemNavigationBarSubscription = _settingsBox
        .watch(key: Settings.transparentSystemNavigationBar)
        .listen((event) => _setSystemUIOverlayStyle());

    isReady.value = true;
    await checkDarkMode();

    debugPrint('读取设置数据成功');
  }

  @override
  void onClose() async {
    await _darkModeSubscription.cancel();
    await _transparentSystemNavigationBarSubscription.cancel();
    await _settingsBox.close();
    isReady.value = false;

    super.onClose();
  }
}

class SettingsBackupData extends BackupData {
  @override
  String get title => '设置';

  SettingsBackupData();

  @override
  Future<void> backup(String dir) async {
    await SettingsService.to._settingsBox.close();

    await copyHiveFileToBackupDir(dir, HiveBoxName.settings);
    progress = 1.0;
  }
}

class SettingsRestoreOperator implements CommonRestoreOperator {
  const SettingsRestoreOperator();

  @override
  Future<void> beforeRestore(String dir) =>
      copyHiveBackupFile(dir, HiveBoxName.settings);

  @override
  Future<void> afterRestore(String dir) async {
    await deleteHiveBackupFile(HiveBoxName.settings);
    await deleteHiveBackupLockFile(HiveBoxName.settings);
  }
}

class FeedIdRestoreData extends RestoreData {
  @override
  String get title => '订阅ID';

  @override
  String get subTitle => '会覆盖现有的订阅ID';

  @override
  CommonRestoreOperator? get commonOperator => const SettingsRestoreOperator();

  FeedIdRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      hiveBackupFileInDir(dir, HiveBoxName.settings).exists();

  @override
  Future<void> restore(String dir) async {
    final box = await Hive.openBox(hiveBackupName(HiveBoxName.settings));
    if (box.containsKey(Settings.feedId)) {
      await SettingsService.to._settingsBox
          .put(Settings.feedId, box.get(Settings.feedId));
    }
    await box.close();

    progress = 1.0;
  }
}

class SettingsRestoreData extends RestoreData {
  static final List<String> _settings = [
    Settings.isRestoreTabs,
    Settings.showImage,
    Settings.showLargeImageInPost,
    Settings.isWatermark,
    Settings.isJumpToLastBrowsePage,
    Settings.isJumpToLastBrowsePosition,
    Settings.isAfterPostRefresh,
    Settings.dismissibleTab,
    Settings.selectCookieBeforePost,
    Settings.forbidDuplicatedPosts,
    Settings.useHtmlFeed,
    Settings.useBackupApi,
    Settings.connectionTimeout,
    Settings.cacheImageCount,
    if (GetPlatform.isMobile || GetPlatform.isMacOS)
      Settings.followPlatformBrightness,
    Settings.addBlueIslandEmoticons,
    Settings.restoreForumPage,
    Settings.addDeleteFeedInThread,
    Settings.longPressButtonToOpenNewTab,
    Settings.maxPagesEachTab,
    Settings.imageDisposeDistance,
    Settings.fixedImageDisposeRatio,
    if (!GetPlatform.isIOS) Settings.useDrawerAndEndDrawer,
    Settings.showBottomBar,
    Settings.autoHideBottomBar,
    Settings.endDrawerContent,
    Settings.autoHideAppBar,
    Settings.hideFloatingButton,
    Settings.autoHideFloatingButton,
    Settings.drawerEdgeDragWidthRatio,
    Settings.swipeablePageDragWidthRatio,
    Settings.compactTabAndForumList,
    if (SettingsService.isAllowTransparentSystemNavigationBar)
      Settings.transparentSystemNavigationBar,
    Settings.showPoCookieTag,
    Settings.poCookieColor,
    Settings.showUserCookieNote,
    Settings.showUserCookieColor,
    Settings.showRelativeTime,
    Settings.showLatestPostTimeInFeed,
    Settings.postHeaderFontSize,
    Settings.postHeaderFontWeight,
    Settings.postHeaderLineHeight,
    Settings.postHeaderLetterSpacing,
    Settings.postContentFontSize,
    Settings.postContentFontWeight,
    Settings.postContentLineHeight,
    Settings.postContentLetterSpacing,
  ];

  @override
  String get title => '设置';

  @override
  String get subTitle => '会覆盖大部分设置';

  @override
  CommonRestoreOperator? get commonOperator => const SettingsRestoreOperator();

  SettingsRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      hiveBackupFileInDir(dir, HiveBoxName.settings).exists();

  @override
  Future<void> restore(String dir) async {
    final settings = SettingsService.to;

    final box = await Hive.openBox(hiveBackupName(HiveBoxName.settings));
    for (final s in _settings) {
      if (box.containsKey(s)) {
        await settings._settingsBox.put(s, box.get(s));
      }
    }
    // initialForum需要特殊处理
    if (box.containsKey(Settings.initialForum)) {
      await settings._settingsBox.put(Settings.initialForum,
          (box.get(Settings.initialForum) as ForumData).copy());
    }
    await box.close();

    progress = 1.0;
  }
}
