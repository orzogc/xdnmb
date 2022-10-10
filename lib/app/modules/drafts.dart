import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:screenshot/screenshot.dart';

import '../data/models/draft.dart';
import '../data/services/draft.dart';
import '../utils/toast.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/post.dart';

class PostDraftsController extends GetxController {
  final List<PostDraftData> _deleted = [];

  @override
  void onClose() {
    for (final draft in _deleted) {
      draft.delete();
    }

    super.onClose();
  }
}

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
    final drafts = PostDraftListService.to;

    return Scaffold(
      appBar: AppBar(title: const Text('草稿')),
      body: drafts.length > 0
          ? LoaderOverlay(
              child: ListView.builder(
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts.draft(drafts.length - index - 1);
                  final isVisible = true.obs;

                  return Obx(
                    () => (draft != null && isVisible.value)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () =>
                                    Get.back<PostDraftData>(result: draft),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      onPressed: () async {
                                        final overlay = context.loaderOverlay;
                                        overlay.show();

                                        final data =
                                            await ScreenshotController()
                                                .captureFromWidget(
                                                    Container(
                                                      width: 300.0,
                                                      color: Colors.white,
                                                      child: PostDraft(
                                                        title: draft.title,
                                                        name: draft.name,
                                                        content: draft.content,
                                                        textStyle:
                                                            const TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    context: context);

                                        overlay.hide();
                                        Get.back<Uint8List>(result: data);
                                      },
                                      icon: const Icon(Icons.screenshot),
                                    ),
                                    IconButton(
                                      onPressed: () => Get.dialog(
                                        ConfirmCancelDialog(
                                          content: '确定删除该草稿？',
                                          onConfirm: () async {
                                            controller._deleted.add(draft);
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
                              if (index != drafts.length - 1)
                                const Divider(height: 10.0, thickness: 1.0),
                            ],
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
            )
          : const Center(child: Text('没有草稿', style: AppTheme.boldRed)),
    );
  }
}
