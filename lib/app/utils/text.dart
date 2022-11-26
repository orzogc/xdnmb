import 'package:flutter/material.dart' hide Element;
import 'package:html_to_text/html_to_text.dart';

import 'regex.dart';
import 'theme.dart';

typedef GetHiddenText = HiddenText Function();

class HiddenText {
  HtmlText? _text;

  bool _isVisible = false;

  HiddenText();

  void _trigger() => _isVisible = !_isVisible;

  void dispose() => _text?.dispose();
}

TextSpan getHiddenText(
    {required BuildContext context,
    required Element element,
    required TextStyle textStyle,
    Color? hiddenColor,
    GetHiddenText? getHiddenText,
    VoidCallback? refresh,
    OnLinkTapCallback? onLinkTap}) {
  assert((getHiddenText != null && refresh != null && onLinkTap != null) ||
      (getHiddenText == null && refresh == null && onLinkTap == null));

  final content = element.innerHtml;
  final size = getTextSize(context, '啊$content', textStyle);

  if (getHiddenText != null && refresh != null && onLinkTap != null) {
    final hiddenText = getHiddenText();

    final text = HtmlText(
      context,
      content,
      onLinkTap: (context, link, text) {
        if (hiddenText._isVisible) {
          onLinkTap(context, link, text);
        } else {
          hiddenText._trigger();
          refresh();
        }
      },
      onTextTap: (context, text) {
        hiddenText._trigger();
        refresh();
      },
      onText: (context, text) => Regex.onText(text),
      onTextRecursiveParse: true,
      textStyle: textStyle,
      overrideTextStyle: TextStyle(
        decoration: hiddenText._isVisible ? null : TextDecoration.lineThrough,
        decorationColor:
            hiddenText._isVisible ? null : (hiddenColor ?? AppTheme.textColor),
        decorationThickness: hiddenText._isVisible ? null : (size.height + 5.0),
      ),
    );

    hiddenText._text?.dispose();
    hiddenText._text = text;

    return text.toTextSpan();
  }

  return htmlToTextSpan(
    context,
    content,
    onText: (context, text) => Regex.onText(text),
    onTextRecursiveParse: true,
    textStyle: textStyle,
    overrideTextStyle: TextStyle(
      decoration: TextDecoration.lineThrough,
      decorationColor: hiddenColor ?? AppTheme.textColor,
      decorationThickness: size.height + 5.0,
    ),
  );
}

String htmlToPlainText(BuildContext context, String html) =>
    htmlToTextSpan(context, html).toPlainText();

Size getTextSize(BuildContext context, String text, TextStyle? style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr)
    ..layout();

  return Size(textPainter.width, textPainter.height);
}

double getLineHeight(BuildContext context, String text, TextStyle? style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr);

  return textPainter.preferredLineHeight;
}

StrutStyle? strutStyleFromHeight(TextStyle? textStyle) =>
    textStyle?.height != null ? StrutStyle(height: textStyle!.height) : null;
