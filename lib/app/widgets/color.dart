import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

import 'dialog.dart';

class ColoredSafeArea extends StatelessWidget {
  final Color? color;

  final Widget child;

  const ColoredSafeArea({super.key, this.color, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color ?? Theme.of(context).primaryColor,
        child: SafeArea(left: false, top: false, right: false, child: child),
      );
}

class ColorListTile extends StatelessWidget {
  final bool enabled;

  final Widget? title;

  final Color color;

  final ValueChanged<Color>? onColorChanged;

  const ColorListTile(
      {super.key,
      this.enabled = true,
      this.title,
      required this.color,
      this.onColorChanged});

  @override
  Widget build(BuildContext context) => ListTile(
        enabled: enabled,
        contentPadding: EdgeInsets.zero,
        visualDensity:
            const VisualDensity(vertical: VisualDensity.minimumDensity),
        onTap: () {
          Color? color_;
          Get.dialog(
            ConfirmCancelDialog(
              contentWidget: HueRingPicker(
                pickerColor: color,
                onColorChanged: (value) => color_ = value,
                enableAlpha: true,
                displayThumbColor: true,
              ),
              onConfirm: () {
                if (color_ != null) {
                  onColorChanged?.call(color_!);
                }

                Get.back();
              },
              onCancel: Get.back,
            ),
          );
        },
        title: title,
        trailing: ColorIndicator(
          HSVColor.fromColor(color),
          key: ValueKey<Color>(color),
          width: 25.0,
          height: 25.0,
        ),
      );
}
