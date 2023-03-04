import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/crypto.dart';
import '../../utils/image.dart';
import '../../utils/padding.dart';
import '../../widgets/dialog.dart';
import '../models/hive.dart';
import '../models/persistent.dart';
import 'settings.dart';
import 'xdnmb_client.dart';

class PersistentDataService extends GetxService {
  static final PersistentDataService to = Get.find<PersistentDataService>();

  static const Duration updateForumListInterval = Duration(hours: 6);

  static const int _maxRecentTags = 5;

  static late final bool isFirstLaunched;

  static late final bool clearImageCache;

  static bool isNavigatorReady = false;

  late final Box _dataBox;

  final RxBool _isKeyboardVisible = false.obs;

  final ValueNotifier<double> bottomHeight = ValueNotifier(0.0);

  double _maxBottomHeight = 0.0;

  final RxBool isReady = false.obs;

  bool get isKeyboardVisible => _isKeyboardVisible.value;

  bool get firstLaunched =>
      _dataBox.get(PersistentData.firstLaunched, defaultValue: true);

  set firstLaunched(bool firstLaunched) =>
      _dataBox.put(PersistentData.firstLaunched, firstLaunched);

  String? get notice => _dataBox.get(PersistentData.notice, defaultValue: null);

  set notice(String? notice) => _dataBox.put(PersistentData.notice, notice);

  DateTime? get noticeDate =>
      _dataBox.get(PersistentData.noticeDate, defaultValue: null);

  set noticeDate(DateTime? date) =>
      _dataBox.put(PersistentData.noticeDate, date);

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

  DateTime? get updateForumListTime =>
      _dataBox.get(PersistentData.updateForumListTime, defaultValue: null);

  set updateForumListTime(DateTime? time) =>
      _dataBox.put(PersistentData.updateForumListTime, time);

  int get controllerStackListIndex =>
      _dataBox.get(PersistentData.controllerStackListIndex, defaultValue: 0);

  set controllerStackListIndex(int index) =>
      _dataBox.put(PersistentData.controllerStackListIndex, index);

  String get imageHashSalt => _dataBox.get(PersistentData.imageHashSalt);

  set imageHashSalt(String salt) =>
      _dataBox.put(PersistentData.imageHashSalt, salt);

  /// 最新的tag在最后
  List<int> get _recentTags =>
      _dataBox.get(PersistentData.recentTags, defaultValue: <int>[]);

  set _recentTags(List<int> tags) =>
      _dataBox.put(PersistentData.recentTags, tags);

  List<int> get recentTags => _recentTags;

  late final ValueListenable<Box> noticeDateListenable;

  StreamSubscription<bool>? _keyboardSubscription;

  static Future<void> getData() async {
    final box = await Hive.openBox(HiveBoxName.data);

    isFirstLaunched = box.get(PersistentData.firstLaunched, defaultValue: true);
    clearImageCache =
        box.get(PersistentData.clearImageCache, defaultValue: true);
  }

  /// 清除全部图片缓存，只运行一次
  static Future<void> clearCacheImage() async {
    if (clearImageCache) {
      await XdnmbImageCacheManager().emptyCache();
      final box = await Hive.openBox(HiveBoxName.data);
      await box.put(PersistentData.clearImageCache, false);
    }
  }

  static double get _bottomHeight => getViewInsets().bottom;

  void saveNotice(Notice notice) {
    if (notice.isValid &&
        (this.notice != notice.content || noticeDate != notice.date)) {
      if (notice.content.isNotEmpty) {
        this.notice = notice.content;
        noticeDate = notice.date;
        SettingsService.to.showNotice = true;

        debugPrint('保存公告成功');
      }
    }
  }

  Future<void> updateNotice() async {
    debugPrint('开始获取公告');

    saveNotice(await XdnmbClientService.to.client.getNotice());
  }

  Future<void> showNotice() async {
    if (SettingsService.to.showNotice) {
      final client = XdnmbClientService.to;
      while (!client.finishGettingNotice) {
        debugPrint('正在等待获取X岛公告');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (notice?.isNotEmpty ?? false) {
        // 需要Navigator显示公告
        while (!isNavigatorReady) {
          debugPrint('正在等待Navigator');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        await showNoticeDialog(showCheckbox: true);
      }
    }
  }

  void updateKeyboardHeight() {
    if (GetPlatform.isMobile) {
      final height = _bottomHeight;

      _maxBottomHeight = max(_maxBottomHeight, height);

      if (bottomHeight.value > height &&
          _maxBottomHeight > 0.0 &&
          keyboardHeight != _maxBottomHeight) {
        keyboardHeight = _maxBottomHeight;
      }

      bottomHeight.value = height;
    }
  }

  void addRecentTag(int tagId) {
    final tags = _recentTags;
    if (tags.contains(tagId)) {
      _recentTags = [...tags.where((element) => element != tagId), tagId];
    } else {
      if (tags.length >= _maxRecentTags) {
        _recentTags = [...tags.skip(1), tagId];
      } else {
        _recentTags = [...tags, tagId];
      }
    }
  }

  void deleteRecentTag(int tagId) {
    final tags = _recentTags;
    if (tags.contains(tagId)) {
      _recentTags = [...tags.where((element) => element != tagId)];
    }
  }

  @override
  void onInit() async {
    super.onInit();

    _dataBox = await Hive.openBox(HiveBoxName.data);

    if (!_dataBox.containsKey(PersistentData.imageHashSalt)) {
      imageHashSalt = randomString(20);
    }

    noticeDateListenable =
        _dataBox.listenable(keys: [PersistentData.noticeDate]);

    if (GetPlatform.isMobile) {
      bottomHeight.value = _bottomHeight;

      _keyboardSubscription = KeyboardVisibilityController()
          .onChange
          .listen((visible) => _isKeyboardVisible.value = visible);
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
