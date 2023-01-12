import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String text;

  final TextStyle? textStyle;

  final StrutStyle? strutStyle;

  // ignore: unused_element
  const Tag({super.key, required this.text, this.textStyle, this.strutStyle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = textStyle != null
        ? textStyle!.apply(color: theme.colorScheme.onPrimary)
        : TextStyle(color: theme.colorScheme.onPrimary);
    final strut = strutStyle ?? StrutStyle.fromTextStyle(style);

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Text(text, style: style, strutStyle: strut),
      ),
    );
  }
}
