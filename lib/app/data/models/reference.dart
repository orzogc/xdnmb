import 'dart:math';

import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/extensions.dart';

part 'reference.g.dart';

@Collection(ignore: {'hashCode'})
class ReferenceData {
  final Id id;

  /// UTC
  DateTime? postTime;

  /// [mainPostId] 等于 [id] 时为主串
  @Index()
  int? mainPostId;

  /// 准确的页数
  ///
  /// 主串页数固定为 1
  int? accuratePage;

  /// 不一定准确的页数
  int? fuzzyPage;

  @ignore
  bool get isMainPost => id == mainPostId;

  @ignore
  int? get page => accuratePage ?? fuzzyPage;

  @ignore
  bool get isComplete =>
      postTime != null && mainPostId != null && accuratePage != null;

  ReferenceData(
      {required this.id,
      DateTime? postTime,
      this.mainPostId,
      this.accuratePage,
      this.fuzzyPage})
      : postTime = postTime?.toUtc();

  ReferenceData.fromPost(
      {required PostBase post,
      this.mainPostId,
      this.accuratePage,
      this.fuzzyPage})
      : id = post.id,
        postTime = post.postTime.toUtc();

  ReferenceData.fromMainPost(PostBase post)
      : id = post.id,
        postTime = post.postTime.toUtc(),
        mainPostId = post.id,
        accuratePage = 1;

  static List<ReferenceData> fromForumThreads(Iterable<ForumThread> threads) =>
      threads.fold(<ReferenceData>[], (list, thread) {
        int replyCount =
            max(thread.mainPost.replyCount - thread.recentReplies.length, 0);

        return list
          ..addAll(thread.recentReplies.fold<List<ReferenceData>>(
              [ReferenceData.fromMainPost(thread.mainPost)],
              (list, post) => list
                ..add(ReferenceData.fromPost(
                    post: post,
                    mainPostId: thread.mainPost.id,
                    fuzzyPage: (++replyCount).postMaxPage))));
      });

  static List<ReferenceData> fromThread(Thread thread, int page) =>
      thread.replies.fold(
          <ReferenceData>[ReferenceData.fromMainPost(thread.mainPost)],
          (list, post) => list
            ..add(ReferenceData.fromPost(
                post: post,
                mainPostId: thread.mainPost.id,
                accuratePage: page)));

  static List<ReferenceData> fromFeeds(Iterable<Feed> feeds) =>
      feeds.fold(<ReferenceData>[], (list, feed) {
        int replyCount = max(feed.replyCount - feed.recentReplies.length, 0);

        return list
          ..addAll(feed.recentReplies.fold<List<ReferenceData>>(
              [ReferenceData.fromMainPost(feed)],
              (list, postId) => list
                ..add(ReferenceData(
                    id: postId,
                    mainPostId: feed.id,
                    fuzzyPage: (++replyCount).postMaxPage))));
      });

  static Iterable<ReferenceData> fromHtmlFeeds(Iterable<HtmlFeed> feeds) =>
      feeds.map((feed) => ReferenceData.fromMainPost(feed));

  void update(ReferenceData other) {
    assert(id == other.id);

    if (other.postTime != null) {
      postTime = other.postTime!.toUtc();
    }
    if (other.mainPostId != null) {
      mainPostId = other.mainPostId;
    }
    if (other.accuratePage != null) {
      accuratePage = other.accuratePage;
    }
    if (accuratePage == null && other.fuzzyPage != null) {
      fuzzyPage = other.fuzzyPage;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceData &&
          id == other.id &&
          postTime == other.postTime &&
          mainPostId == other.mainPostId &&
          accuratePage == other.accuratePage &&
          fuzzyPage == other.fuzzyPage);

  @ignore
  @override
  int get hashCode =>
      Object.hash(id, postTime, mainPostId, accuratePage, fuzzyPage);
}
