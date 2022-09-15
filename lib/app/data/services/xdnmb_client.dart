import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/exception.dart';
import '../../utils/toast.dart';
import 'forum.dart';
import 'persistent.dart';

class XdnmbClientService extends GetxService {
  static XdnmbClientService get to => Get.find<XdnmbClientService>();

  // TODO: timeout
  final XdnmbApi client;

  Notice? notice;

  List<Timeline>? timelineList;

  ForumList? forumList;

  late final HashMap<int, Timeline> timelineMap;

  late final HashMap<int, Forum> forumMap;

  final RxBool isReady = false.obs;

  XdnmbClientService() : client = XdnmbApi();

  String? forumName(int forumId, {bool isTimeline = false}) =>
      isTimeline ? timelineMap[forumId]?.showName : forumMap[forumId]?.showName;

  int? maxPage(int forumId, {bool isTimeline = false}) =>
      isTimeline ? timelineMap[forumId]?.maxPage : forumMap[forumId]?.maxPage;

  Widget forumNameWidget(int forumId,
      {required NameWidgetBuilder builder,
      Widget empty = const SizedBox.shrink(),
      bool isTimeline = false}) {
    final name = forumName(forumId, isTimeline: isTimeline);

    return name == null ? empty : builder(name);
  }

  @override
  void onReady() async {
    super.onReady();

    try {
      debugPrint('开始获取X岛公告');

      notice = await client.getNotice();

      final data = PersistentDataService.to;
      if (data.isReady.value) {
        data.updateNotice(notice!);
      }

      debugPrint('获取X岛公告成功');
    } catch (e) {
      showToast('获取X岛公告失败：${exceptionMessage(e)}');
    }

    try {
      debugPrint('开始更新X岛服务');

      await client.updateUrls();

      timelineList = await client.getTimelineList();
      timelineMap = HashMap.fromEntries(
          timelineList!.map((timeline) => MapEntry(timeline.id, timeline)));

      forumList = await client.getForumList();
      forumMap = HashMap.fromEntries(
          forumList!.forumList.map((forum) => MapEntry(forum.id, forum)));

      final forums = ForumListService.to;
      if (forums.isReady.value) {
        await forums.updateForums();
      }

      debugPrint('更新X岛服务成功');
    } catch (e) {
      if (timelineList == null) {
        timelineMap = HashMap.fromIterable([]);
      }
      if (forumList == null) {
        forumMap = HashMap.fromIterable([]);
      }
      showToast('更新X岛服务失败：${exceptionMessage(e)}');
    }

    isReady.value = true;
  }

  @override
  void onClose() {
    client.close();
    isReady.value = false;

    super.onClose();
  }
}
