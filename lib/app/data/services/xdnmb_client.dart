import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/exception.dart';
import '../../utils/http_client.dart';
import '../../utils/reference.dart';
import '../../utils/toast.dart';
import '../models/reference.dart';
import 'forum.dart';
import 'persistent.dart';
import 'settings.dart';
import 'tag.dart';

class ReferenceWithData {
  final HtmlReference reference;

  final ReferenceData data;

  const ReferenceWithData(this.reference, this.data);
}

class XdnmbClientService extends GetxService {
  static final XdnmbClientService to = Get.find<XdnmbClientService>();

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

  Future<List<ForumThread>> getForum(int forumId,
      {int page = 1, String? cookie}) async {
    final threads = await client.getForum(forumId, page: page, cookie: cookie);
    ReferenceDatabase.addForumThreads(threads);
    TagService.to.addForumThreads(threads);

    return threads;
  }

  Future<List<ForumThread>> getTimeline(int timelineId,
      {int page = 1, String? cookie}) async {
    final threads =
        await client.getTimeline(timelineId, page: page, cookie: cookie);
    ReferenceDatabase.addForumThreads(threads);
    TagService.to.addForumThreads(threads);

    return threads;
  }

  Future<Thread> getThread(int mainPostId,
      {int page = 1, String? cookie, bool isFirstPage = false}) async {
    final thread =
        await client.getThread(mainPostId, page: page, cookie: cookie);
    ReferenceDatabase.addThread(thread, page);
    TagService.to.addThread(thread, isFirstPage);

    return thread;
  }

  Future<Thread> getOnlyPoThread(int mainPostId,
      {int page = 1, String? cookie, bool isFirstPage = false}) async {
    final thread =
        await client.getOnlyPoThread(mainPostId, page: page, cookie: cookie);
    ReferenceDatabase.addThread(thread, page);
    TagService.to.addThread(thread, isFirstPage);

    return thread;
  }

  Future<Reference> getReference(int postId,
      {String? cookie, int? mainPostId}) async {
    final reference = await client.getReference(postId, cookie: cookie);
    ReferenceDatabase.addPost(post: reference, mainPostId: mainPostId);
    TagService.to.updatePosts([reference]);

    return reference;
  }

  Future<ReferenceWithData> getHtmlReference(int postId,
      {String? cookie}) async {
    final reference = await client.getHtmlReference(postId, cookie: cookie);
    TagService.to.updatePosts([reference]);
    final data = await ReferenceDatabase.addPost(
        post: reference, mainPostId: reference.mainPostId);

    return ReferenceWithData(reference, data);
  }

  Future<List<Feed>> getFeed(String feedId,
      {int page = 1, String? cookie}) async {
    final feeds = await client.getFeed(feedId, page: page, cookie: cookie);
    ReferenceDatabase.addFeeds(feeds);
    TagService.to.addFeeds(feeds);

    return feeds;
  }

  Future<LastPost?> getLastPost({String? cookie}) async {
    final post = await client.getLastPost(cookie: cookie);
    if (post != null) {
      ReferenceDatabase.addPost(
          post: post,
          mainPostId: post.mainPostId ?? post.id,
          accuratePage: post.mainPostId == null ? 1 : null);
    }

    return post;
  }

  @override
  void onReady() async {
    super.onReady();

    final data = PersistentDataService.to;
    final settings = SettingsService.to;

    try {
      debugPrint('开始获取X岛公告');

      Notice? notice;
      if (PersistentDataService.isFirstLaunched) {
        // 首次启动应用尝试循环5次获取公告
        for (var i = 0; i < 5; i++) {
          debugPrint('正在循环获取X岛公告');

          try {
            notice = await client.getNotice();
            break;
          } catch (e) {
            if (i == 4) {
              rethrow;
            }
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
      if (notice != null) {
        data.saveNotice(notice);
      }

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

    while (!data.isReady.value) {
      debugPrint('正在等待读取数据');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      debugPrint('开始更新X岛版块列表');

      if (PersistentDataService.isFirstLaunched) {
        // 首次启动应用必须获取到版块列表
        while (true) {
          debugPrint('正在循环获取X岛版块列表');

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
