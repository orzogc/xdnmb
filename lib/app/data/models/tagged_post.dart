import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'tagged_post.g.dart';

@collection
class TaggedPost implements PostBase {
  @override
  final Id id;

  @override
  int? forumId;

  @ignore
  @override
  String image = '';

  @ignore
  @override
  String imageExtension = '';

  /// UTC
  @override
  DateTime postTime;

  @override
  String userHash;

  @override
  String name;

  @override
  String title;

  @override
  String content;

  @override
  bool isAdmin;

  bool hasImage;

  /// 最近添加标签的时间
  ///
  /// UTC
  @Index()
  DateTime taggedTime;

  @Index(type: IndexType.value)
  List<int> tags;

  @ignore
  @override
  int? get replyCount => null;

  @ignore
  @override
  bool? get isSage => null;

  @ignore
  @override
  bool? get isHidden => null;

  @ignore
  bool get hasTag => tags.isNotEmpty;

  TaggedPost(
      {required this.id,
      this.forumId,
      required DateTime postTime,
      required this.userHash,
      required String name,
      required String title,
      required String content,
      required this.isAdmin,
      required this.hasImage,
      required DateTime taggedTime,
      required this.tags})
      : assert(tags.isNotEmpty),
        postTime = postTime.toUtc(),
        name = name != '无名氏' ? name : '',
        title = title != '无标题' ? title : '',
        content = content.isNotEmpty ? content : '分享图片',
        taggedTime = taggedTime.toUtc();

  TaggedPost.fromPost(
      {required PostBase post, DateTime? taggedTime, required List<int> tags})
      : this(
            id: post.id,
            forumId: post.forumId,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content,
            isAdmin: post.isAdmin,
            hasImage: post.hasImage,
            taggedTime: taggedTime ?? DateTime.now(),
            tags: tags);

  void update(PostBase post) {
    assert(id == post.id);
    assert(hasTag);

    if (post.forumId != null) {
      forumId = post.forumId;
    }
    image = '';
    imageExtension = '';
    postTime = post.postTime.toUtc();
    userHash = post.userHash;
    name = post.name != '无名氏' ? post.name : '';
    title = post.title != '无标题' ? post.title : '';
    content = post.content.isNotEmpty ? post.content : '分享图片';
    isAdmin = post.isAdmin;
    hasImage = post.hasImage;
  }

  /// 添加标签成功返回`true`，有重复标签返回`false`
  bool addTag(int tag) {
    assert(hasTag);

    if (!tags.contains(tag)) {
      tags.add(tag);
      taggedTime = DateTime.now().toUtc();

      return true;
    } else {
      return false;
    }
  }

  /// 删除标签，返回是否还有标签
  bool deleteTag(int tag) {
    assert(hasTag);

    tags.removeWhere((element) => element == tag);

    return hasTag;
  }
}
