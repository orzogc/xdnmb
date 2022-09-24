import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

import '../modules/post_list.dart';
import 'dialog.dart';

class PageButton extends StatelessWidget {
  final PostListController controller;

  final int? maxPage;

  const PageButton({super.key, required this.controller, this.maxPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () => postListDialog<int>(JumpPageDialog(
              currentPage: controller.currentPage.value, maxPage: maxPage))
          .then((page) {
        if (page != null) {
          controller.refreshPage(page);
          controller.currentPage.value = page;
        }
      }),
      child: Obx(
        () => Text(
          '${controller.currentPage.value}',
          style: theme.textTheme.headline6
              ?.apply(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
}
