import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/post_list.dart';

// 可能需要在Obx里调用
EdgeInsets getPadding(BuildContext context) {
  final view = View.of(context);
  // 为了通知`padding`的变化
  final _ = PostListView.padding.value;

  return EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio);
}

// 可能需要在Obx里调用
EdgeInsets getViewPadding(BuildContext context) {
  final view = View.of(context);
  // 为了通知`viewPadding`的变化
  final _ = PostListView.viewPadding.value;

  return EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio);
}

EdgeInsets getViewInsets() {
  final view = View.of(Get.context!);

  return EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio);
}
