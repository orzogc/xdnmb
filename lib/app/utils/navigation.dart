import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/stack.dart';
import '../modules/post_list.dart';
import 'extensions.dart';

GlobalKey<NavigatorState>? postListkey([int? index]) =>
    Get.nestedKey(ControllerStacksService.to.getKeyId(index));

void postListBack<T>({
  T? result,
  bool closeOverlays = false,
  bool canPop = true,
  int? index,
}) =>
    Get.maybePop(
        result: result,
        closeOverlays: closeOverlays,
        canPop: canPop,
        id: ControllerStacksService.to.getKeyId(index));

void postListPop([int? index]) =>
    Get.back(id: ControllerStacksService.to.getKeyId(index));

void popAllPopup([int? index]) {
  Get.until((route) {
    if (route is PopupRoute) {
      return false;
    }
    return true;
  }, id: ControllerStacksService.to.getKeyId(index));
}

void openNewTabBackground(PostListController controller) =>
    ControllerStacksService.to.addNewStack(controller);

void openNewTab(PostListController controller) {
  openNewTabBackground(controller);
  PostListPage.pageKey.currentState!.jumpToLast();
}
