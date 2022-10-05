import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'post.g.dart';

@Collection()
class PostData {
  Id id = Isar.autoIncrement;

  int? postId;

  int forumId;

  String? image;

  String? imageExtension;

  // UTC
  @Index()
  DateTime postTime;

  String userHash;

  String? name;

  String? title;

  String content;

  bool isAdmin;

  PostData(
      {this.postId,
      required this.forumId,
      String? image,
      String? imageExtension,
      required DateTime postTime,
      required this.userHash,
      String? name,
      String? title,
      required String content,
      this.isAdmin = false})
      : image = image != null ? (image.isNotEmpty ? image : null) : null,
        imageExtension = imageExtension != null
            ? (imageExtension.isNotEmpty ? imageExtension : null)
            : null,
        postTime = postTime.toUtc(),
        name = name != null
            ? ((name.isNotEmpty && name != '无名氏') ? name : null)
            : null,
        title = title != null
            ? ((title.isNotEmpty && title != '无标题') ? title : null)
            : null,
        content = content.isNotEmpty ? content : '分享图片';

  PostData.fromPost(Post post)
      : this(
            postId: post.id,
            forumId: post.forumId,
            image: post.image,
            imageExtension: post.imageExtension,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content,
            isAdmin: post.isAdmin);

  Post toPost() => Post(
      id: postId ?? 0,
      forumId: forumId,
      replyCount: 0,
      image: image ?? '',
      imageExtension: imageExtension ?? '',
      postTime: postTime,
      userHash: userHash,
      name: name ?? '',
      title: title ?? '',
      content: content,
      isAdmin: isAdmin);

  void update(Post post) {
    postId = post.id;
    forumId = post.forumId;
    image = post.image.isNotEmpty ? post.image : null;
    imageExtension =
        post.imageExtension.isNotEmpty ? post.imageExtension : null;
    postTime = post.postTime.toUtc();
    userHash = post.userHash;
    name = (post.name.isNotEmpty && post.name != '无名氏') ? post.name : null;
    title = (post.title.isNotEmpty && post.title != '无标题') ? post.title : null;
    content = post.content.isNotEmpty ? post.content : '分享图片';
    isAdmin = post.isAdmin;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostData &&
          id == other.id &&
          postId == other.postId &&
          forumId == other.forumId &&
          image == other.image &&
          imageExtension == other.imageExtension &&
          postTime == other.postTime &&
          userHash == other.userHash &&
          name == other.name &&
          title == other.title &&
          content == other.content &&
          isAdmin == other.isAdmin);

  @ignore
  @override
  int get hashCode => Object.hash(id, postId, forumId, image, imageExtension,
      postTime, userHash, name, title, content, isAdmin);
}
