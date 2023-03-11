import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/tag.dart';
import 'tagged.dart';

class Tag extends StatelessWidget {
  final String text;

  final TextStyle? textStyle;

  final StrutStyle? strutStyle;

  final Color? backgroundColor;

  final Color? textColor;

  final VoidCallback? onTap;

  const Tag(
      {super.key,
      required this.text,
      this.textStyle,
      this.strutStyle,
      this.backgroundColor,
      this.textColor,
      this.onTap});

  Tag.fromTagData(
      {super.key,
      required TagData tag,
      this.textStyle,
      this.strutStyle,
      this.onTap})
      : text = tag.name,
        backgroundColor = tag.backgroundColor,
        textColor = tag.textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        textStyle?.apply(color: textColor ?? theme.colorScheme.onPrimary) ??
            TextStyle(color: textColor ?? theme.colorScheme.onPrimary);
    final strut = strutStyle ?? StrutStyle.fromTextStyle(style);

    final tag = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.primaryColor,
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
          strutStyle: strut,
        ),
      ),
    );

    return onTap != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(onTap: onTap, child: tag),
          )
        : tag;
  }
}

class PostTag extends StatelessWidget {
  final TaggedPostListController controller;

  final TextStyle? textStyle;

  final StrutStyle? strutStyle;

  const PostTag(
      {super.key, required this.controller, this.textStyle, this.strutStyle});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tag = controller.tag;

      return tag != null
          ? Tag.fromTagData(
              tag: tag,
              textStyle: !controller.tagExists
                  ? (textStyle?.apply(
                          decoration: TextDecoration.combine([
                        TextDecoration.lineThrough,
                        if (textStyle?.decoration != null)
                          textStyle!.decoration!,
                      ])) ??
                      const TextStyle(decoration: TextDecoration.lineThrough))
                  : textStyle,
              strutStyle: strutStyle)
          : const SizedBox.shrink();
    });
  }
}
