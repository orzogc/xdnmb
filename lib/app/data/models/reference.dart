import 'dart:math';

import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/extensions.dart';

part 'reference.g.dart';

@collection
class ReferenceData {
  final Id id;

  /// UTC
  DateTime? postTime;

  /// [mainPostId]等于[id]时为主串
  @Index()
  int? mainPostId;

  /// 准确的页数
  ///
  /// 主串页数固定为1
  int? accuratePage;

  /// 不一定准确的页数
  int? fuzzyPage;

  @ignore
  bool get isMainPost => id == mainPostId;

  @ignore
  int? get page => accuratePage ?? fuzzyPage;

  @ignore
  bool get isDone =>
      postTime != null && mainPostId != null && accuratePage != null;

  ReferenceData(
      {required this.id,
      this.postTime,
      this.mainPostId,
      this.accuratePage,
      this.fuzzyPage});

  ReferenceData.fromPost(
      {required PostBase post,
      this.mainPostId,
      this.accuratePage,
      this.fuzzyPage})
      : id = post.id,
        postTime = post.postTime;

  static List<ReferenceData> fromForumThreads(Iterable<ForumThread> threads) =>
      threads.fold(<ReferenceData>[], (list, thread) {
        int replyCount =
            max(thread.mainPost.replyCount - thread.recentReplies.length, 0);

        return list
          ..addAll(thread.recentReplies.fold<List<ReferenceData>>(
              [
                ReferenceData.fromPost(
                    post: thread.mainPost,
                    mainPostId: thread.mainPost.id,
                    accuratePage: 1)
              ],
              (list, post) => list
                ..add(ReferenceData.fromPost(
                    post: post,
                    mainPostId: thread.mainPost.id,
                    fuzzyPage: (++replyCount).postMaxPage))));
      });

  static List<ReferenceData> fromThread(Thread thread, int page) =>
      thread.replies.fold(
          <ReferenceData>[
            ReferenceData.fromPost(
                post: thread.mainPost,
                mainPostId: thread.mainPost.id,
                accuratePage: 1)
          ],
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
              [
                ReferenceData.fromPost(
                    post: feed, mainPostId: feed.id, accuratePage: 1)
              ],
              (list, postId) => list
                ..add(ReferenceData(
                    id: postId,
                    mainPostId: feed.id,
                    fuzzyPage: (++replyCount).postMaxPage))));
      });

  void update(ReferenceData other) {
    if (other.postTime != null) {
      postTime = other.postTime;
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
