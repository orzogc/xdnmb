import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../models/forum.dart';
import '../models/hive.dart';
import '../../utils/notify.dart';
import '../../utils/toast.dart';
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
  static ForumListService get to => Get.find<ForumListService>();

  late final Box<ForumData> _forumBox;

  final RxBool isReady = false.obs;

  final Notifier updateForumNameNotifier = Notifier();

  late final ValueListenable<Box<ForumData>> forumsListenable;

  /// key为顺序，value为[_forumBox]里的index
  final ValueNotifier<HashMap<int, int>> displayedForumIndexNotifier =
      ValueNotifier(HashMap());

  late HashMap<_ForumKey, _ForumValue> _forumMap;

  final HashSet<int> _deprecatedForumId = HashSet();

  int get displayedForumsCount => displayedForumIndexNotifier.value.length;

  Iterable<ForumData> get forums => _forumBox.values;

  Iterable<ForumData> get displayedForums =>
      forums.where((forum) => forum.isDisplayed);

  Iterable<ForumData> get hiddenForums =>
      forums.where((forum) => forum.isHidden);

  void _updateDisplayedForumIndexNotifier() =>
      displayedForumIndexNotifier.value = HashMap.of(
          (HashMap.of(forums.toList().asMap())
                ..removeWhere((key, forum) => forum.isHidden))
              .keys
              .toList()
              .asMap());

  void _updateForumMap() =>
      _forumMap = HashMap.fromEntries(forums.map((forum) => MapEntry(
          _ForumKey.fromForumData(forum), _ForumValue.fromForum(forum))));

  void _notifyUpdateForumName() => updateForumNameNotifier.notify();

  Future<void> _getHtmlForum(int forumId) async {
    if (_forumMap.isNotEmpty &&
        !_forumMap.containsKey(_ForumKey(forumId, false)) &&
        !_deprecatedForumId.contains(forumId)) {
      _deprecatedForumId.add(forumId);

      try {
        final client = XdnmbClientService.to.client;
        final forum = await client.getHtmlForumInfo(forumId);
        await addForum(ForumData.fromHtmlForum(forum));
        debugPrint('增加废弃版块：${forum.name}');
      } catch (e) {
        debugPrint('获取HtmlForum失败：$e');
      }
    }
  }

  /// 返回[ForumData]，不会自动请求未知版块的信息
  ForumData? forum(int forumId, {bool isTimeline = false}) {
    try {
      return forums.firstWhere(
          (forum) => forum.id == forumId && forum.isTimeline == isTimeline);
    } catch (e) {
      debugPrint('ForumListService里没有ID为$forumId的版块/时间线');

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
          if (timeline != null) {
            await _forumBox.putAt(
                entry.key,
                ForumData.fromTimeline(timeline,
                    userDefinedName: entry.value.userDefinedName,
                    isHidden: entry.value.isHidden));
          } else {
            await _forumBox.putAt(entry.key, entry.value.deprecate());
          }
        } else {
          final forum = forumMap[entry.value.id];
          if (forum != null) {
            await _forumBox.putAt(
                entry.key,
                ForumData.fromForum(forum,
                    userDefinedName: entry.value.userDefinedName,
                    isHidden: entry.value.isHidden));
          } else {
            await _forumBox.putAt(entry.key, entry.value.deprecate());
          }
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
    final index_ = displayedForumIndexNotifier.value[index];

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
    await _forumBox.close();
    isReady.value = false;

    super.onClose();
  }
}
