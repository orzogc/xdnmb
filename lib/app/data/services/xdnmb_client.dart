import 'package:flutter/material.dart' hide Image;
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

class XdnmbClient extends XdnmbApi {
  XdnmbClient(
      {super.client,
      super.connectionTimeout,
      super.idleTimeout,
      super.userAgent});

  @override
  Future<List<ForumThread>> getForum(int forumId,
      {int page = 1, String? cookie}) async {
    final threads = await super.getForum(forumId, page: page, cookie: cookie);
    ReferenceDatabase.addForumThreads(threads);
    TagService.addForumThreads(threads);

    return threads;
  }

  @override
  Future<List<ForumThread>> getTimeline(int timelineId,
      {int page = 1, String? cookie}) async {
    final threads =
        await super.getTimeline(timelineId, page: page, cookie: cookie);
    ReferenceDatabase.addForumThreads(threads);
    TagService.addForumThreads(threads);

    return threads;
  }

  @override
  Future<Thread> getThread(int mainPostId,
      {int page = 1, String? cookie, bool isFirstPage = false}) async {
    final thread =
        await super.getThread(mainPostId, page: page, cookie: cookie);
    ReferenceDatabase.addThread(thread, page);
    TagService.addThread(thread, isFirstPage);

    return thread;
  }

  @override
  Future<Thread> getOnlyPoThread(int mainPostId,
      {int page = 1, String? cookie, bool isFirstPage = false}) async {
    final thread =
        await super.getOnlyPoThread(mainPostId, page: page, cookie: cookie);
    ReferenceDatabase.addThread(thread, page);
    TagService.addThread(thread, isFirstPage);

    return thread;
  }

  @override
  Future<Reference> getReference(int postId,
      {String? cookie, int? mainPostId}) async {
    final reference = await super.getReference(postId, cookie: cookie);
    ReferenceDatabase.addPost(post: reference, mainPostId: mainPostId);
    TagService.updatePosts([reference]);

    return reference;
  }

  Future<ReferenceWithData> xdnmbGetHtmlReference(int postId,
      {String? cookie}) async {
    final reference = await super.getHtmlReference(postId, cookie: cookie);
    TagService.updatePosts([reference]);
    final data = await ReferenceDatabase.addPost(
        post: reference, mainPostId: reference.mainPostId);

    return ReferenceWithData(reference, data);
  }

  @override
  Future<List<Feed>> getFeed(String feedId,
      {int page = 1, String? cookie}) async {
    final feeds = await super.getFeed(feedId, page: page, cookie: cookie);
    ReferenceDatabase.addFeeds(feeds);
    TagService.addFeeds(feeds);

    return feeds;
  }

  @override
  Future<(List<HtmlFeed>, int?)> getHtmlFeed(
      {int page = 1, String? cookie}) async {
    final (feeds, maxPage) =
        await super.getHtmlFeed(page: page, cookie: cookie);
    ReferenceDatabase.addHtmlFeeds(feeds);
    TagService.addFeeds(feeds);

    return (feeds, maxPage);
  }

  Future<void> xdnmbAddFeed(int mainPostId, {String? cookie}) async {
    final settings = SettingsService.to;

    if (settings.useHtmlFeed) {
      await super.addHtmlFeed(mainPostId, cookie: cookie);
    } else {
      await super.addFeed(settings.feedId, mainPostId, cookie: cookie);
    }
  }

  Future<void> xdnmbDeleteFeed(int mainPostId, {String? cookie}) async {
    final settings = SettingsService.to;

    if (settings.useHtmlFeed) {
      await super.deleteHtmlFeed(mainPostId, cookie: cookie);
    } else {
      await super.deleteFeed(settings.feedId, mainPostId, cookie: cookie);
    }
  }

  @override
  Future<LastPost?> getLastPost({String? cookie}) async {
    final post = await super.getLastPost(cookie: cookie);
    if (post != null) {
      ReferenceDatabase.addPost(
          post: post,
          mainPostId: post.mainPostId ?? post.id,
          accuratePage: post.mainPostId == null ? 1 : null);
    }

    return post;
  }
}

class XdnmbClientService extends GetxService {
  static final XdnmbClientService to = Get.find<XdnmbClientService>();

  final XdnmbClient client;

  bool finishGettingNotice = false;

  final RxBool hasSetWhetherUseBackupApi = false.obs;

  bool hasUpdateUrls = false;

  final RxBool isReady = false.obs;

  XdnmbClientService()
      : client = XdnmbClient(
            client: XdnmbHttpClient.httpClient,
            connectionTimeout: SettingsService.connectionTimeoutSecond,
            idleTimeout: XdnmbHttpClient.idleTimeout,
            userAgent: XdnmbHttpClient.userAgent);

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

    while (!settings.isReady.value) {
      debugPrint('正在等待读取设置');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      client.useBackupApi(settings.useBackupApi);
      hasSetWhetherUseBackupApi.value = true;
      await client.updateUrls();
    } catch (e) {
      debugPrint('更新 X 岛链接失败：$e');
    } finally {
      hasUpdateUrls = true;
    }

    try {
      debugPrint('开始获取 X 岛公告');

      Notice? notice;
      if (PersistentDataService.isFirstLaunched) {
        // 首次启动应用尝试循环 5 次获取公告
        for (var i = 0; i < 5; i++) {
          debugPrint('正在循环获取 X 岛公告');

          try {
            notice = await client.getNotice();
            break;
          } catch (e) {
            if (i == 4) {
              rethrow;
            }
            debugPrint('获取 X 岛公告失败：${exceptionMessage(e)}');
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      } else {
        notice = await client.getNotice();
      }

      while (!data.isReady.value) {
        debugPrint('正在等待读取数据');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('保存 X 岛公告');
      if (notice != null) {
        data.saveNotice(notice);
      }

      debugPrint('获取 X 岛公告成功');
    } catch (e) {
      // autocorrect: false
      showToast('获取X岛公告失败：${exceptionMessage(e)}');
      // autocorrect: true
    } finally {
      finishGettingNotice = true;
    }

    while (!data.isReady.value) {
      debugPrint('正在等待读取数据');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      debugPrint('开始更新 X 岛版块列表');

      if (PersistentDataService.isFirstLaunched) {
        // 首次启动应用必须获取到版块列表
        while (true) {
          debugPrint('正在循环获取 X 岛版块列表');

          try {
            await _updateForumList();
            break;
          } catch (e) {
            debugPrint('获取 X 岛版块列表失败：${exceptionMessage(e)}');
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      } else if (data.updateForumListTime != null) {
        if (DateTime.now().difference(data.updateForumListTime!) >=
            PersistentDataService.updateForumListInterval) {
          debugPrint('版块列表过期，更新 X 岛版块列表');
          await _updateForumList();
        } else {
          debugPrint('版块列表未过期，取消更新');
        }
      } else {
        debugPrint('没有更新记录，更新 X 岛版块列表');
        await _updateForumList();
      }

      debugPrint('更新 X 岛版块列表成功');
    } catch (e) {
      // 失败的话确保下次启动会更新版块列表
      data.updateForumListTime == null;
      // autocorrect: false
      showToast('更新X岛版块列表失败：${exceptionMessage(e)}');
      // autocorrect: true
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
