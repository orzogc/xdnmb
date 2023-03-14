import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/controller.dart';
import '../widgets/color.dart';
import '../widgets/edit_post.dart';

class EditPostController extends GetxController {
  final PostListType postListType;

  final int id;

  final int? forumId;

  final String? poUserHash;

  final String? title;

  final String? name;

  final String? content;

  final String? imagePath;

  final Uint8List? imageData;

  final bool? isWatermark;

  final String? reportReason;

  final bool? isAttachDeviceInfo;

  EditPostController(
      {required this.postListType,
      required this.id,
      this.forumId,
      this.poUserHash,
      this.title,
      this.name,
      this.content,
      this.imagePath,
      this.imageData,
      this.isWatermark,
      this.reportReason,
      this.isAttachDeviceInfo});

  bool get hasText =>
      (title?.isNotEmpty ?? false) ||
      (name?.isNotEmpty ?? false) ||
      (content?.isNotEmpty ?? false);

  bool get isImagePainted => imagePath == null && imageData != null;
}

class EditPostBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(Get.arguments as EditPostController);
  }
}

// TODO: 单独页面返回要有提示保存
class EditPostView extends GetView<EditPostController> {
  static EditPostCallback? get _editPost => EditPostCallback.page;

  const EditPostView({super.key});

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          final controller = _editPost?.toController();
          Get.back(result: controller);

          return false;
        },
        child: ColoredSafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(controller.postListType.isForumType ? '发表新串' : '回串'),
            ),
            body: EditPost.fromController(controller: controller),
          ),
        ),
      );
}
