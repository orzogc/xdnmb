import 'package:flutter/material.dart';

import '../data/models/tag.dart';

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
