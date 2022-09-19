import 'package:isar/isar.dart';

part 'post.g.dart';

@Collection()
class PostData {
  final Id id = Isar.autoIncrement;

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
      this.image,
      this.imageExtension,
      required DateTime postTime,
      required this.userHash,
      this.name,
      this.title,
      required this.content,
      this.isAdmin = false})
      : postTime = postTime.toUtc() {
    if ((name?.isEmpty ?? true) &&
        (title?.isEmpty ?? true) &&
        content.isEmpty) {
      content = '分享图片';
    }
  }
}
