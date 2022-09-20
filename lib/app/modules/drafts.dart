import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/draft.dart';
import '../data/services/drafts.dart';
import '../utils/toast.dart';
import '../widgets/bilistview.dart';
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
  static const int _draftsEachPage = 20;

  const PostDraftsView({super.key});

  @override
  Widget build(BuildContext context) {
    final drafts = PostDraftsService.to;
    final length = drafts.length;

    return Scaffold(
      appBar: AppBar(title: const Text('草稿箱')),
      body: BiListView<PostDraftData>(
        initialPage: 1,
        fetch: (page) async {
          final start = max(length - _draftsEachPage * page, 0);
          final end = max(length - _draftsEachPage * (page - 1), 0);

          if (end <= start) {
            return [];
          }

          final List<PostDraftData> draftList = [];

          for (var i = end - 1; i >= start; i--) {
            final draft = drafts.draft(i);
            if (draft != null) {
              draftList.add(draft);
            }
          }

          return draftList;
        },
        itemBuilder: (context, draft, index) {
          final isVisible = true.obs;

          return Obx(
            () => isVisible.value
                ? Card(
                    key: UniqueKey(),
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 1.5,
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
                                  isVisible.value = false;

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
                  )
                : const SizedBox.shrink(),
          );
        },
        separator: const SizedBox.shrink(),
        noItemsFoundBuilder: (context) => const Center(
          child: Text(
            '没有草稿',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        canRefreshAtBottom: false,
      ),
    );
  }
}
