import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/forum.dart';
import '../models/hive.dart';
import '../../utils/toast.dart';
import 'xdnmb_client.dart';

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

  // TODO: 改进效率
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
      await _displayedBox.addAll(client.timelineList!
          .map((timeline) => ForumData.fromTimeline(timeline))
          .followedBy(client.forumList!.forumList
              .map((forum) => ForumData.fromForum(forum))));
    } else {
      final displayed = _displayedBox.values;
      final hidden = _hiddenBox.values;

      final newDisplayed = <ForumData>[];
      for (final forum in displayed) {
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
      for (final forum in hidden) {
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
      final allForums = displayed.followedBy(hidden);
      for (final timeline in client.timelineList!) {
        if (!allForums
            .any((forum) => forum.isTimeline && forum.id == timeline.id)) {
          newForums.add(ForumData.fromTimeline(timeline));
        }
      }
      for (final forum_ in client.forumList!.forumList) {
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

  //ForumData? hiddenForum(int index) => _hiddenBox.getAt(index);

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
      forum(forumId, isTimeline: isTimeline)?.forumName;

  int? maxPage(int forumId, {bool isTimeline = false}) =>
      forum(forumId, isTimeline: isTimeline)?.maxPage;

  Widget forumNameWidget(int forumId,
      {required NameWidgetBuilder builder,
      Widget empty = const SizedBox.shrink(),
      bool isTimeline = false}) {
    final name = forumName(forumId, isTimeline: isTimeline);

    return name == null ? empty : builder(name);
  }

  Future<void> addForum(ForumData forum) => _displayedBox.add(forum);

  @override
  void onInit() async {
    super.onInit();

    _displayedBox = await Hive.openBox<ForumData>(HiveBoxName.displayedForums);
    _hiddenBox = await Hive.openBox<ForumData>(HiveBoxName.hiddenForums);

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
