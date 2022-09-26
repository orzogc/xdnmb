import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/forum.dart';
import '../models/hive.dart';
import '../../utils/toast.dart';
import 'xdnmb_client.dart';

class _ForumKey {
  final int id;

  final bool isTimeline;

  bool get isForum => !isTimeline;

  const _ForumKey(this.id, this.isTimeline);

  _ForumKey.fromForum(ForumData forum) : this(forum.id, forum.isTimeline);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ForumKey && id == other.id && isTimeline == other.isTimeline);

  @override
  int get hashCode => Object.hash(id, isTimeline);
}

class _ForumValue {
  final String name;

  final int maxPage;

  const _ForumValue(this.name, this.maxPage);

  _ForumValue.fromForum(ForumData forum) : this(forum.forumName, forum.maxPage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ForumValue && name == other.name && maxPage == other.maxPage);

  @override
  int get hashCode => Object.hash(name, maxPage);
}

typedef NameWidgetBuilder = Widget Function(String name);

class ForumListService extends GetxService {
  static ForumListService get to => Get.find<ForumListService>();

  late final Box<ForumData> _displayedBox;

  late final Box<ForumData> _hiddenBox;

  final RxBool isReady = false.obs;

  int get displayedLength => _displayedBox.length;

  Iterable<ForumData> get displayedForums => _displayedBox.values;

  Iterable<ForumData> get hiddenForums => _hiddenBox.values;

  Iterable<ForumData> get forums => displayedForums.followedBy(hiddenForums);

  late final ValueListenable<Box<ForumData>> displayedForumListenable;

  HashMap<_ForumKey, _ForumValue> _forumMap = HashMap();

  void _updateForumMap() =>
      _forumMap = HashMap.fromEntries(forums.map((forum) =>
          MapEntry(_ForumKey.fromForum(forum), _ForumValue.fromForum(forum))));

  ForumData? forum(int forumId, {bool isTimeline = false}) {
    try {
      return forums.firstWhere(
          (forum) => forum.isTimeline == isTimeline && forum.id == forumId);
    } catch (e) {
      debugPrint('ForumListService里没有ID为$forumId的板块/时间线');

      return null;
    }
  }

  Future<void> updateForums() async {
    final client = XdnmbClientService.to;

    if (_displayedBox.isEmpty && _hiddenBox.isEmpty) {
      await _displayedBox.addAll(client.timelineMap.values
          .map((timeline) => ForumData.fromTimeline(timeline))
          .followedBy(client.forumMap.values
              .map((forum) => ForumData.fromForum(forum))));
    } else {
      final newDisplayed = <ForumData>[];
      for (final forum in displayedForums) {
        if (forum.isTimeline) {
          if (client.timelineMap.containsKey(forum.id)) {
            newDisplayed.add(ForumData.fromTimeline(
                client.timelineMap[forum.id]!, forum.userDefinedName));
          } else {
            newDisplayed.add(forum.deprecate());
          }
        } else {
          if (client.forumMap.containsKey(forum.id)) {
            newDisplayed.add(ForumData.fromForum(
                client.forumMap[forum.id]!, forum.userDefinedName));
          } else {
            newDisplayed.add(forum.deprecate());
          }
        }
      }

      final newHidden = <ForumData>[];
      for (final forum in hiddenForums) {
        if (forum.isTimeline) {
          if (client.timelineMap.containsKey(forum.id)) {
            newHidden.add(ForumData.fromTimeline(
                client.timelineMap[forum.id]!, forum.userDefinedName));
          } else {
            newHidden.add(forum.deprecate());
          }
        } else {
          if (client.forumMap.containsKey(forum.id)) {
            newHidden.add(ForumData.fromForum(
                client.forumMap[forum.id]!, forum.userDefinedName));
          } else {
            newHidden.add(forum.deprecate());
          }
        }
      }

      final newForums = <ForumData>[];
      final allForums = forums;
      for (final timeline in client.timelineMap.values) {
        if (!allForums
            .any((forum) => forum.isTimeline && forum.id == timeline.id)) {
          newForums.add(ForumData.fromTimeline(timeline));
        }
      }
      for (final forum_ in client.forumMap.values) {
        if (!allForums.any((forum) => forum.isForum && forum.id == forum_.id)) {
          newForums.add(ForumData.fromForum(forum_));
        }
      }

      if (newForums.isNotEmpty) {
        final newForumString =
            newForums.map((forum) => forum.forumName).join(' ');
        showToast('新板块：$newForumString');
      }

      await _displayedBox.clear();
      await _hiddenBox.clear();
      await _displayedBox.addAll(newDisplayed.followedBy(newForums));
      await _hiddenBox.addAll(newHidden);
    }
  }

  ForumData? displayedForum(int index) => _displayedBox.getAt(index);

  Future<void> saveForums(
      {required List<ForumData> displayedForums,
      required List<ForumData> hiddenForums}) async {
    await _displayedBox.clear();
    await _hiddenBox.clear();
    await _displayedBox.addAll(displayedForums);
    await _hiddenBox.addAll(hiddenForums);
  }

  Future<void> hideForum(ForumData forum) async {
    await forum.delete();
    await _hiddenBox.add(forum);
  }

  String? forumName(int forumId, {bool isTimeline = false}) =>
      _forumMap[_ForumKey(forumId, isTimeline)]?.name;

  int? maxPage(int forumId, {bool isTimeline = false}) =>
      _forumMap[_ForumKey(forumId, isTimeline)]?.maxPage;

  Future<void> addForum(ForumData forum) => _displayedBox.add(forum);

  @override
  void onInit() async {
    super.onInit();

    _displayedBox = await Hive.openBox<ForumData>(HiveBoxName.displayedForums);
    _hiddenBox = await Hive.openBox<ForumData>(HiveBoxName.hiddenForums);

    _updateForumMap();
    _displayedBox.watch().listen((event) => _updateForumMap());
    _hiddenBox.watch().listen((event) => _updateForumMap());

    displayedForumListenable = _displayedBox.listenable();

    isReady.value = true;
    debugPrint('读取板块列表成功');
  }

  @override
  void onClose() async {
    await _displayedBox.close();
    await _hiddenBox.close();
    isReady.value = false;

    super.onClose();
  }
}
