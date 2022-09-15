import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  EditPostController(
      {required this.postListType,
      required this.id,
      this.forumId,
      this.title,
      this.name,
      this.content,
      this.imagePath,
      this.isWatermark});

  bool hasText() =>
      (title?.isNotEmpty ?? false) ||
      (name?.isNotEmpty ?? false) ||
      (content?.isNotEmpty ?? false);
}

class EditPostBinding implements Bindings {
  @override
  void dependencies() {
    int index = int.tryParse(Get.parameters['postListType'] ??
            '${PostListType.timeline.index}') ??
        PostListType.timeline.index;
    if (index >= PostListType.values.length) {
      index = PostListType.timeline.index;
    }

    Get.put(EditPostController(
      postListType: PostListType.values[index],
      id: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
      forumId: int.tryParse(Get.parameters['forumId'] ?? ''),
      title: Get.parameters['title'],
      name: Get.parameters['name'],
      content: Get.parameters['content'],
      imagePath: Get.parameters['imagePath'],
      isWatermark: Get.parameters['isWatermark'] != null ? true : false,
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
