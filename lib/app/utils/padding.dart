import 'package:flutter/material.dart';

EdgeInsets getViewPadding() => EdgeInsets.fromWindowPadding(
    WidgetsBinding.instance.window.viewPadding,
    WidgetsBinding.instance.window.devicePixelRatio);

EdgeInsets getViewInsets() => EdgeInsets.fromWindowPadding(
    WidgetsBinding.instance.window.viewInsets,
    WidgetsBinding.instance.window.devicePixelRatio);
