import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/exception.dart';
import '../../utils/http_client.dart';
import '../../utils/toast.dart';
import 'forum.dart';
import 'persistent.dart';
import 'settings.dart';

class XdnmbClientService extends GetxService {
  static XdnmbClientService get to => Get.find<XdnmbClientService>();

  // TODO: timeout
  final XdnmbApi client;

  bool hasGotNotice = false;

  final RxBool isReady = false.obs;

  XdnmbClientService()
      : client = XdnmbApi(
            client: XdnmbHttpClient.httpClient,
            connectionTimeout: XdnmbHttpClient.connectionTimeout,
            idleTimeout: XdnmbHttpClient.idleTimeout);

  Future<void> _updateForumList() async {
    final timelineList = await client.getTimelineList();
    final timelineMap = {
      for (final timeline in timelineList) timeline.id: timeline
    };

    final forumList = await client.getForumList();
    final forumMap = {for (final forum in forumList.forumList) forum.id: forum};

    final forums = ForumListService.to;
    if (forums.isReady.value) {
      await forums.updateForums(timelineMap, forumMap);
    }
  }

  @override
  void onReady() async {
    super.onReady();

    final data = PersistentDataService.to;

    try {
      debugPrint('开始获取X岛公告');

      final notice = await client.getNotice();

      if (data.isReady.value && SettingsService.to.isReady.value) {
        debugPrint('保存公告');
        data.saveNotice(notice);
      }

      debugPrint('获取X岛公告成功');
    } catch (e) {
      showToast('获取X岛公告失败：${exceptionMessage(e)}');
    } finally {
      hasGotNotice = true;
    }

    try {
      debugPrint('开始更新X岛服务');

      await client.updateUrls();

      if (data.isReady.value) {
        if (data.updateForumListTime != null) {
          if (DateTime.now().difference(data.updateForumListTime!) >=
              PersistentDataService.updateForumListInterval) {
            debugPrint('版块列表过期，更新版块列表');
            await _updateForumList();
            data.updateForumListTime = DateTime.now();
          } else {
            debugPrint('版块列表未过期，取消更新');
          }
        } else {
          debugPrint('没有更新记录，更新版块列表');
          await _updateForumList();
          data.updateForumListTime = DateTime.now();
        }
      } else {
        debugPrint('更新版块列表');
        await _updateForumList();
      }

      debugPrint('更新X岛服务成功');
    } catch (e) {
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
