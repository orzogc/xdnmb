import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../modules/post_list.dart';
import '../../widgets/feed.dart';
import '../../widgets/forum.dart';
import '../../widgets/history.dart';
import '../../widgets/thread.dart';

part 'controller.g.dart';

class DateTimeRangeAdapter extends TypeAdapter<DateTimeRange> {
  @override
  final int typeId = 6;

  @override
  DateTimeRange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return DateTimeRange(
      start: fields[0] as DateTime,
      end: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DateTimeRange obj) => writer
    ..writeByte(2)
    ..writeByte(0)
    ..write(obj.start)
    ..writeByte(1)
    ..write(obj.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateTimeRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId);

  @override
  int get hashCode => typeId.hashCode;
}

@HiveType(typeId: 7)
class PostBaseData implements PostBase {
  @HiveField(0)
  @override
  final int id;

  @HiveField(1)
  @override
  final int? forumId;

  @HiveField(2)
  @override
  final int? replyCount;

  @override
  String get image => '';

  @override
  String get imageExtension => '';

  @HiveField(3)
  @override
  final DateTime postTime;

  @HiveField(4)
  @override
  final String userHash;

  @HiveField(5)
  @override
  final String name;

  @HiveField(6)
  @override
  final String title;

  @HiveField(7)
  @override
  final String content;

  @HiveField(8)
  @override
  final bool? isSage;

  @HiveField(9)
  @override
  final bool isAdmin;

  @HiveField(10)
  @override
  final bool? isHidden;

  const PostBaseData(
      {required this.id,
      this.forumId,
      this.replyCount,
      required this.postTime,
      required this.userHash,
      this.name = '',
      this.title = '',
      required this.content,
      this.isSage,
      this.isAdmin = false,
      this.isHidden});

  PostBaseData.fromPost(PostBase post)
      : this(
            id: post.id,
            forumId: post.forumId,
            replyCount: post.replyCount,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content,
            isSage: post.isSage,
            isAdmin: post.isAdmin,
            isHidden: post.isHidden);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostBaseData &&
          id == other.id &&
          forumId == other.forumId &&
          replyCount == other.replyCount &&
          image == other.image &&
          imageExtension == other.imageExtension &&
          postTime == other.postTime &&
          userHash == other.userHash &&
          name == other.name &&
          title == other.title &&
          content == other.content &&
          isSage == other.isSage &&
          isAdmin == other.isAdmin &&
          isHidden == other.isHidden);

  @override
  int get hashCode => Object.hash(
      id,
      forumId,
      replyCount,
      image,
      imageExtension,
      postTime,
      userHash,
      name,
      title,
      content,
      isSage,
      isAdmin,
      isHidden);
}

@HiveType(typeId: 8)
enum PostListType {
  @HiveField(0)
  thread,

  @HiveField(1)
  onlyPoThread,

  @HiveField(2)
  forum,

  @HiveField(3)
  timeline,

  @HiveField(4)
  feed,

  @HiveField(5)
  history;

  bool get isThread => this == thread;

  bool get isOnlyPoThread => this == onlyPoThread;

  bool get isForum => this == forum;

  bool get isTimeline => this == timeline;

  bool get isFeed => this == feed;

  bool get isHistory => this == history;

  bool get isThreadType => isThread || isOnlyPoThread;

  bool get isForumType => isForum || isTimeline;

  bool get hasForumId => isThreadType || isForum;

  bool get canPost => isThreadType || isForumType;

  bool get isXdnmbApi => isThreadType || isForumType || isFeed;
}

@HiveType(typeId: 9)
class PostListControllerData extends HiveObject {
  @HiveField(0)
  final PostListType postListType;

  @HiveField(1)
  final int? id;

  @HiveField(2)
  final int page;

  @HiveField(3)
  final PostBaseData? post;

  @HiveField(4)
  final int? bottomBarIndex;

  @HiveField(5)
  final List<DateTimeRange?>? dateRange;

  PostListControllerData(
      {required this.postListType,
      this.id,
      this.page = 1,
      this.post,
      this.bottomBarIndex,
      this.dateRange});

  factory PostListControllerData.fromController(PostListController controller) {
    switch (controller.postListType) {
      case PostListType.thread:
      case PostListType.onlyPoThread:
        return PostListControllerData(
            postListType: (controller as ThreadTypeController).postListType,
            id: controller.id,
            page: controller.page,
            post: controller.post != null
                ? PostBaseData.fromPost(controller.post!)
                : null);
      case PostListType.forum:
      case PostListType.timeline:
        return PostListControllerData(
            postListType: controller.postListType,
            id: controller.id,
            page: controller.page);
      case PostListType.feed:
        return PostListControllerData(
            postListType: controller.postListType, page: controller.page);
      case PostListType.history:
        return PostListControllerData(
            postListType: (controller as HistoryController).postListType,
            page: controller.page,
            bottomBarIndex: controller.bottomBarIndex,
            dateRange: controller.dateRange);
    }
  }

  PostListController toController([bool isRetainForumPage = true]) {
    switch (postListType) {
      case PostListType.thread:
        return ThreadController(id: id!, page: page, post: post);
      case PostListType.onlyPoThread:
        return OnlyPoThreadController(id: id!, page: page, post: post);
      case PostListType.forum:
        return ForumController(id: id!, page: isRetainForumPage ? page : 1);
      case PostListType.timeline:
        return TimelineController(id: id!, page: isRetainForumPage ? page : 1);
      case PostListType.feed:
        return FeedController(page);
      case PostListType.history:
        return HistoryController(
            page: page, bottomBarIndex: bottomBarIndex!, dateRange: dateRange!);
    }
  }
}
