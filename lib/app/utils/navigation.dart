import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/post_list.dart';
import '../modules/stack_cache.dart';

GlobalKey<NavigatorState>? postListkey([int? index]) =>
    Get.nestedKey(StackCacheView.getKeyId(index));

void postListBack<T>({
  T? result,
  bool closeOverlays = false,
  bool canPop = true,
  int? index,
}) =>
    Get.back(
        result: result,
        closeOverlays: closeOverlays,
        canPop: canPop,
        id: StackCacheView.getKeyId(index));

void popOnce([int? index]) {
  bool hasPopped = false;
  Get.until((route) {
    if (!hasPopped) {
      if (route is! PopupRoute) {
        StackCacheView.popController(index);
      }
      hasPopped = true;
      return false;
    }
    return true;
  }, id: StackCacheView.getKeyId(index));
}

void openNewTabBackground(PostListController controller) =>
    StackCacheView.addController(controller);

void openNewTab(PostListController controller) {
  openNewTabBackground(controller);
  PostListPage.pageKey.currentState!.jumpToLast();
}
