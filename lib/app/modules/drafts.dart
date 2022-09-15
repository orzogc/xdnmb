import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/models/draft.dart';
import '../data/services/drafts.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/post.dart';

class PostDraftsController extends GetxController {}

class PostDraftsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(PostDraftsController());
  }
}

class PostDraftsView extends GetView<PostDraftsController> {
  const PostDraftsView({super.key});

  @override
  Widget build(BuildContext context) {
    final drafts = PostDraftsService.to;

    return Scaffold(
      appBar: AppBar(title: const Text('草稿箱')),
      body: ValueListenableBuilder<Box<PostDraftData>>(
        valueListenable: drafts.draftListenable,
        builder: (context, value, child) {
          final list = drafts.drafts.toList().reversed.toList();

          return drafts.length > 0
              ? ListView.builder(
                  itemCount: drafts.length,
                  itemBuilder: (context, index) {
                    final draft = list[index];

                    return Card(
                      key: UniqueKey(),
                      child: InkWell(
                        onTap: () => Get.back<PostDraftData>(result: draft),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PostDraft(
                                title: draft.title,
                                name: draft.name,
                                content: draft.content,
                                contentMaxLines: 8,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.dialog(
                                ConfirmCancelDialog(
                                  content: '确定删除该草稿？',
                                  onConfirm: () async {
                                    await draft.delete();

                                    showToast('已删除该草稿');
                                    Get.back();
                                  },
                                  onCancel: () => Get.back(),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text(
                    '没有草稿',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
        },
      ),
    );
  }
}
