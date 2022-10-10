import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'forum.g.dart';

@HiveType(typeId: 1)
class ForumData extends HiveObject implements ForumBase {
  @HiveField(0)
  @override
  final int id;

  @HiveField(1, defaultValue: '未知板块')
  @override
  final String name;

  @HiveField(2, defaultValue: '')
  @override
  final String displayName;

  @HiveField(3, defaultValue: '')
  @override
  final String message;

  @HiveField(4, defaultValue: 100)
  @override
  final int maxPage;

  @HiveField(5, defaultValue: false)
  final bool isTimeline;

  @HiveField(6, defaultValue: null)
  final int? forumGroupId;

  @HiveField(7, defaultValue: false)
  final bool isDeprecated;

  @HiveField(8, defaultValue: null)
  String? userDefinedName;

  bool get isForum => !isTimeline;

  String get forumName =>
      (userDefinedName != null && userDefinedName!.isNotEmpty)
          ? userDefinedName!
          : showName;

  ForumData(
      {required this.id,
      required this.name,
      this.displayName = '',
      this.message = '',
      required this.maxPage,
      this.isTimeline = false,
      this.forumGroupId,
      this.isDeprecated = false,
      this.userDefinedName});

  ForumData.fromTimeline(Timeline timeline, [this.userDefinedName])
      : id = timeline.id,
        name = timeline.name,
        displayName = timeline.displayName,
        message = timeline.message,
        maxPage = timeline.maxPage,
        isTimeline = true,
        forumGroupId = null,
        isDeprecated = false;

  ForumData.fromForum(Forum forum, [this.userDefinedName])
      : id = forum.id,
        name = forum.name,
        displayName = forum.displayName,
        message = forum.message,
        maxPage = forum.maxPage,
        isTimeline = false,
        forumGroupId = forum.forumGroupId,
        isDeprecated = false;

  ForumData deprecate() => ForumData(
      id: id,
      name: name,
      displayName: displayName,
      message: message,
      maxPage: maxPage,
      isTimeline: isTimeline,
      forumGroupId: forumGroupId,
      isDeprecated: true,
      userDefinedName: userDefinedName);

  Future<void> editUserDefinedName(String? name) async {
    userDefinedName = name;
    await save();
  }

  ForumData copy() => ForumData(
      id: id,
      name: name,
      displayName: displayName,
      message: message,
      maxPage: maxPage,
      isTimeline: isTimeline,
      forumGroupId: forumGroupId,
      isDeprecated: isDeprecated,
      userDefinedName: userDefinedName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ForumData &&
          id == other.id &&
          name == other.name &&
          displayName == other.displayName &&
          message == other.message &&
          maxPage == other.maxPage &&
          isTimeline == other.isTimeline &&
          forumGroupId == other.forumGroupId &&
          isDeprecated == other.isDeprecated &&
          userDefinedName == other.userDefinedName);

  @override
  int get hashCode => Object.hash(id, name, displayName, message, maxPage,
      isTimeline, forumGroupId, isDeprecated, userDefinedName);
}

@HiveType(typeId: 5)
class BlockForumData extends HiveObject {
  @HiveField(0)
  final int forumId;

  @HiveField(1)
  final int timelineId;

  BlockForumData({required this.forumId, required this.timelineId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockForumData &&
          forumId == other.forumId &&
          timelineId == other.timelineId);

  @override
  int get hashCode => Object.hash(forumId, timelineId);
}
