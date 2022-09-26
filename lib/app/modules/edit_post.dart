import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/extensions.dart';
import '../widgets/edit_post.dart';
import 'post_list.dart';

class EditPostController extends GetxController {
  final PostListType postListType;

  final int id;

  final int? forumId;

  final String? title;

  final String? name;

  final String? content;

  final String? imagePath;

  final bool? isWatermark;

  final String? reportReason;

  EditPostController(
      {required this.postListType,
      required this.id,
      this.forumId,
      this.title,
      this.name,
      this.content,
      this.imagePath,
      this.isWatermark,
      this.reportReason});

  bool hasText() =>
      (title?.isNotEmpty ?? false) ||
      (name?.isNotEmpty ?? false) ||
      (content?.isNotEmpty ?? false);
}

class EditPostBinding implements Bindings {
  @override
  void dependencies() {
    int index = Get.parameters['postListType'].tryParseInt() ??
        PostListType.timeline.index;
    if (index >= PostListType.values.length) {
      index = PostListType.timeline.index;
    }

    Get.put(EditPostController(
      postListType: PostListType.values[index],
      id: Get.parameters['id'].tryParseInt() ?? 0,
      forumId: Get.parameters['forumId'].tryParseInt(),
      title: Get.parameters['title'],
      name: Get.parameters['name'],
      content: Get.parameters['content'],
      imagePath: Get.parameters['imagePath'],
      isWatermark: Get.parameters['isWatermark'].tryParseBool(),
      reportReason: Get.parameters['reportReason'],
    ));
  }
}

class EditPostView extends GetView<EditPostController> {
  final GlobalKey<EditPostState> _editKey = GlobalKey();

  EditPostView({super.key});

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          final controller = _editKey.currentState?.toController();
          Get.back(result: controller);

          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(controller.postListType.isForumType() ? '发新串' : '回串'),
          ),
          body: EditPost.fromController(key: _editKey, controller: controller),
        ),
      );
}
