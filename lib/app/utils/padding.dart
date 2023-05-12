import 'package:flutter/material.dart';
import 'package:get/get.dart';

EdgeInsets getViewPadding(BuildContext context) => EdgeInsets.fromViewPadding(
    View.of(context).viewPadding, View.of(context).devicePixelRatio);

EdgeInsets getViewInsets() => EdgeInsets.fromViewPadding(
    View.of(Get.context!).viewInsets, View.of(Get.context!).devicePixelRatio);
