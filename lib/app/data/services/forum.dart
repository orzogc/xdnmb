import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/backup.dart';
import '../../utils/toast.dart';
import '../../widgets/listenable.dart';
import '../models/forum.dart';
import '../models/hive.dart';
import 'xdnmb_client.dart';

class _ForumKey {
  final int id;

  final bool isTimeline;

  bool get isForum => !isTimeline;

  const _ForumKey(this.id, this.isTimeline);

  _ForumKey.fromTimeline(Timeline timeline) : this(timeline.id, true);

  _ForumKey.fromForum(Forum forum) : this(forum.id, false);

  _ForumKey.fromForumData(ForumData forum) : this(forum.id, forum.isTimeline);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ForumKey && id == other.id && isTimeline == other.isTimeline);

  @override
  int get hashCode => Object.hash(id, isTimeline);
}

class _ForumValue {
  final String name;

  final String displayName;

  final int maxPage;

  final bool isDeprecated;

  const _ForumValue(
      this.name, this.displayName, this.maxPage, this.isDeprecated);

  _ForumValue.fromForum(ForumData forum)
      : this(forum.forumName, forum.forumDisplayName, forum.maxPage,
            forum.isDeprecated);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ForumValue &&
          name == other.name &&
          displayName == other.displayName &&
          maxPage == other.maxPage &&
          isDeprecated == other.isDeprecated);

  @override
  int get hashCode => Object.hash(name, displayName, maxPage, isDeprecated);
}

class ForumListService extends GetxService {
  static final ForumListService to = Get.find<ForumListService>();

  late final Box<ForumData> _forumBox;

  final RxBool isReady = false.obs;

  final Notifier updateForumNameNotifier = Notifier();

  late final ValueListenable<Box<ForumData>> forumsListenable;

  /// key 为顺序，value 为 [_forumBox] 里的 index
  final HashMap<int, int> _displayedForumIndexMap = HashMap();

  final Notifier displayedForumIndexNotifier = Notifier();

  final HashMap<_ForumKey, _ForumValue> _forumMap = HashMap();

  /// 应用本次运行期间新增加的废弃版块 ID，防止短时间内多次重复请求 [_getHtmlForum]
  final HashSet<int> _deprecatedForumId = HashSet();

  int get displayedForumsCount => _displayedForumIndexMap.length;

  Iterable<ForumData> get forums => _forumBox.values;

  Iterable<ForumData> get displayedForums =>
      forums.where((forum) => forum.isDisplayed);

  Iterable<ForumData> get hiddenForums =>
      forums.where((forum) => forum.isHidden);

  void _updateDisplayedForumIndexNotifier() {
    _displayedForumIndexMap.clear();
    _displayedForumIndexMap.addAll(
        (Map<int, ForumData>.of(forums.toList().asMap())
              ..removeWhere((key, forum) => forum.isHidden))
            .keys
            .toList()
            .asMap());

    displayedForumIndexNotifier.notify();
  }

  void _updateForumMap() {
    _forumMap.clear();
    _forumMap.addEntries(forums.map((forum) => MapEntry(
        _ForumKey.fromForumData(forum), _ForumValue.fromForum(forum))));
  }

  void _notifyUpdateForumName() => updateForumNameNotifier.notify();

  Future<void> _getHtmlForum(int forumId) async {
    if (_forumMap.isNotEmpty &&
        !_forumMap.containsKey(_ForumKey(forumId, false)) &&
        !_deprecatedForumId.contains(forumId)) {
      _deprecatedForumId.add(forumId);

      try {
        final forum =
            await XdnmbClientService.to.client.getHtmlForumInfo(forumId);
        await addForum(ForumData.fromHtmlForum(forum));
        debugPrint('增加废弃版块：${forum.name}');
      } catch (e) {
        debugPrint('获取 HtmlForum 失败：$e');
      }
    }
  }

  /// 返回 [ForumData]，不会自动请求未知版块的信息
  ForumData? forum(int forumId, {bool isTimeline = false}) {
    try {
      return forums.firstWhere(
          (forum) => forum.id == forumId && forum.isTimeline == isTimeline);
    } catch (e) {
      debugPrint('ForumListService 里没有 ID 为$forumId 的版块/时间线');

      return null;
    }
  }

  Future<void> updateForums(
      Map<int, Timeline> timelineMap, Map<int, Forum> forumMap) async {
    if (_forumBox.isEmpty) {
      await _forumBox.addAll(timelineMap.values
          .map((timeline) => ForumData.fromTimeline(timeline))
          .followedBy(
              forumMap.values.map((forum) => ForumData.fromForum(forum))));
    } else {
      for (final entry in forums.toList().asMap().entries) {
        if (entry.value.isTimeline) {
          final timeline = timelineMap[entry.value.id];
          await _forumBox.putAt(
              entry.key,
              timeline != null
                  ? ForumData.fromTimeline(timeline,
                      userDefinedName: entry.value.userDefinedName,
                      isHidden: entry.value.isHidden)
                  : entry.value.deprecate());
        } else {
          final forum = forumMap[entry.value.id];
          await _forumBox.putAt(
              entry.key,
              forum != null
                  ? ForumData.fromForum(forum,
                      userDefinedName: entry.value.userDefinedName,
                      isHidden: entry.value.isHidden)
                  : entry.value.deprecate());
        }
      }

      _updateForumMap();
      final newForums = <ForumData>[];
      for (final timeline in timelineMap.values) {
        if (!_forumMap.containsKey(_ForumKey.fromTimeline(timeline))) {
          newForums.add(ForumData.fromTimeline(timeline));
        }
      }
      for (final forum in forumMap.values) {
        if (!_forumMap.containsKey(_ForumKey.fromForum(forum))) {
          newForums.add(ForumData.fromForum(forum));
        }
      }

      if (newForums.isNotEmpty) {
        final newForumString =
            newForums.map((forum) => forum.forumDisplayName).join(' ');
        showToast('新版块：$newForumString');

        await _forumBox.addAll(newForums);
      }
    }

    _updateDisplayedForumIndexNotifier();
    _updateForumMap();
    _notifyUpdateForumName();
  }

  ForumData? displayedForum(int index) {
    final index_ = _displayedForumIndexMap[index];

    return index_ != null ? _forumBox.getAt(index_) : null;
  }

  Future<void> saveForums(
      {required List<ForumData> displayedForums,
      required List<ForumData> hiddenForums}) async {
    await _forumBox.clear();
    _forumBox.addAll(displayedForums.followedBy(hiddenForums));

    _updateDisplayedForumIndexNotifier();
  }

  Future<void> displayForum(ForumData forum) async {
    await forum.setIsHidden(false);

    _updateDisplayedForumIndexNotifier();
  }

  Future<void> hideForum(ForumData forum) async {
    await forum.setIsHidden(true);

    _updateDisplayedForumIndexNotifier();
  }

  Future<void> setForumName(ForumData forum, String? name) async {
    await forum.setUserDefinedName(name);

    _updateForumMap();
    _notifyUpdateForumName();
  }

  /// 返回版块名字，会自动请求未知版块的信息
  String? forumName(int forumId,
      {bool isTimeline = false, bool isDisplay = true}) {
    final name = isDisplay
        ? _forumMap[_ForumKey(forumId, isTimeline)]?.displayName
        : _forumMap[_ForumKey(forumId, isTimeline)]?.name;
    if (name != null) {
      return name;
    }

    if (isTimeline) {
      return '时间线';
    }
    _getHtmlForum(forumId);

    return null;
  }

  int maxPage(int forumId, {bool isTimeline = false}) =>
      _forumMap[_ForumKey(forumId, isTimeline)]?.maxPage ??
      (isTimeline ? 20 : 100);

  Future<void> addForum(ForumData forum) async {
    await _forumBox.add(forum);

    _updateDisplayedForumIndexNotifier();
    _updateForumMap();
    _notifyUpdateForumName();
  }

  ForumData? findForum(String name) {
    try {
      return forums.firstWhere((forum) => forum.isForum && forum.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateForum(int index, ForumData forum) =>
      _forumBox.putAt(index, forum);

  @override
  void onInit() async {
    super.onInit();

    _forumBox = await Hive.openBox<ForumData>(HiveBoxName.forums);

    forumsListenable = _forumBox.listenable();

    _updateDisplayedForumIndexNotifier();
    _updateForumMap();

    isReady.value = true;
    debugPrint('读取版块列表成功');
  }

  @override
  void onClose() async {
    updateForumNameNotifier.dispose();
    await _forumBox.close();
    isReady.value = false;

    super.onClose();
  }
}

class ForumListBackupData extends BackupData {
  @override
  String get title => '时间线和版块';

  ForumListBackupData();

  @override
  Future<void> backup(String dir) async {
    await ForumListService.to._forumBox.close();

    await copyHiveFileToBackupDir(dir, HiveBoxName.forums);
    progress = 1.0;
  }
}

class ForumListRestoreData extends RestoreData {
  @override
  String get title => '时间线和版块';

  @override
  String get subTitle => '会覆盖时间线和版块的自定义名字、顺序和是否显示/隐藏';

  ForumListRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      hiveBackupFileInDir(dir, HiveBoxName.forums).exists();

  @override
  Future<void> restore(String dir) async {
    final forumService = ForumListService.to;

    final file = await copyHiveBackupFile(dir, HiveBoxName.forums);
    final box =
        await Hive.openBox<ForumData>(hiveBackupName(HiveBoxName.forums));
    final backupMap = HashMap.fromEntries(box.values
        .map((forum) => MapEntry(_ForumKey.fromForumData(forum), forum)));
    final Map<_ForumKey, ForumData> map = {
      for (final forum in forumService._forumBox.values)
        _ForumKey.fromForumData(forum): forum,
    };

    // 覆盖版块的自定义名字
    for (final forum in map.values) {
      final backupForum = backupMap[_ForumKey.fromForumData(forum)];
      if (backupForum != null &&
          (backupForum.userDefinedName?.isNotEmpty ?? false) &&
          forum.userDefinedName != backupForum.userDefinedName) {
        forum.userDefinedName = backupForum.userDefinedName;
      }
    }

    // 添加本地没有的版块
    map.addEntries(box.values
        .where((forum) =>
            !forumService._forumMap.containsKey(_ForumKey.fromForumData(forum)))
        .map((forum) => MapEntry(_ForumKey.fromForumData(forum), forum)));

    // 恢复版块排序和显示/隐藏
    await forumService._forumBox.clear();
    for (final backupForum in box.values) {
      final key = _ForumKey.fromForumData(backupForum);
      final forum = map[key];
      if (forum != null) {
        forum.isHidden = backupForum.isHidden;
        await forumService._forumBox.add(forum.copy());
        map.remove(key);
      } else {
        debugPrint('存在未保存的版块数据');
      }
    }
    if (map.isNotEmpty) {
      await forumService._forumBox
          .addAll(map.values.map((forum) => forum.copy()));
    }

    await box.close();
    await file.delete();
    await deleteHiveBackupLockFile(HiveBoxName.forums);

    progress = 1.0;
  }
}
