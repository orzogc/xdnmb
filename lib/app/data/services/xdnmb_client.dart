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

  // TODO: 允许用户设置timeout
  final XdnmbApi client;

  bool finishGettingNotice = false;

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

    while (!forums.isReady.value) {
      debugPrint('正在等待读取版块数据');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await forums.updateForums(timelineMap, forumMap);

    PersistentDataService.to.updateForumListTime = DateTime.now();
  }

  @override
  void onReady() async {
    super.onReady();

    final data = PersistentDataService.to;
    final settings = SettingsService.to;

    try {
      debugPrint('开始获取X岛公告');

      late final Notice notice;
      if (PersistentDataService.isFirstLaunched) {
        while (true) {
          debugPrint('正在获取X岛公告');

          try {
            notice = await client.getNotice();
            break;
          } catch (e) {
            debugPrint('获取X岛公告失败：${exceptionMessage(e)}');
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      } else {
        notice = await client.getNotice();
      }

      while (!(data.isReady.value && settings.isReady.value)) {
        debugPrint('正在等待读取数据和设置');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('保存X岛公告');
      data.saveNotice(notice);

      debugPrint('获取X岛公告成功');
    } catch (e) {
      showToast('获取X岛公告失败：${exceptionMessage(e)}');
    } finally {
      finishGettingNotice = true;
    }

    try {
      await client.updateUrls();
    } catch (e) {
      debugPrint('更新X岛链接失败：$e');
    }

    try {
      debugPrint('开始更新X岛版块列表');

      if (PersistentDataService.isFirstLaunched) {
        while (true) {
          debugPrint('正在获取X岛版块列表');

          try {
            await _updateForumList();
            break;
          } catch (e) {
            debugPrint('获取X岛版块列表失败：${exceptionMessage(e)}');
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      } else if (data.updateForumListTime != null) {
        if (DateTime.now().difference(data.updateForumListTime!) >=
            PersistentDataService.updateForumListInterval) {
          debugPrint('版块列表过期，更新X岛版块列表');
          await _updateForumList();
        } else {
          debugPrint('版块列表未过期，取消更新');
        }
      } else {
        debugPrint('没有更新记录，更新X岛版块列表');
        await _updateForumList();
      }

      debugPrint('更新X岛版块列表成功');
    } catch (e) {
      // 失败的话确保下次启动会更新版块列表
      data.updateForumListTime == null;
      showToast('更新X岛版块列表失败：${exceptionMessage(e)}');
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
