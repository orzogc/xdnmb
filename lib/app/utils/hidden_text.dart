import 'package:flutter/material.dart' hide Element;
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';

import 'regex.dart';
import 'theme.dart';
import 'url.dart';

class _Key {
  final String text;

  final bool isVisible;

  const _Key(this.text, this.isVisible);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _Key && text == other.text && isVisible == other.isVisible);

  @override
  int get hashCode => Object.hash(text, isVisible);
}

InlineSpan onHiddenText(
    {required BuildContext context,
    required Element element,
    required TextStyle textStyle,
    bool canTap = false,
    String? poUserHash}) {
  final isVisible = false.obs;

  return TextSpan(
    children: [
      htmlToTextSpan(
        context,
        element.innerHtml,
        onText: (context, text) => Regex.onReference(text),
        onTextRecursiveParse: true,
        buildText: (context, text, textStyle, link) {
          if (text == '\n' || text == '\n\n') {
            return TextSpan(text: text);
          }

          return WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Obx(
              () {
                final Widget textWidget = Text(
                  text,
                  style: textStyle.merge(
                    isVisible.value
                        ? null
                        : TextStyle(
                            foreground: Paint()
                              ..color = Get.isDarkMode
                                  ? AppTheme.colorDark
                                  : Colors.black,
                          ),
                  ),
                );

                return DecoratedBox(
                  key: ValueKey(_Key(text, isVisible.value)),
                  decoration: BoxDecoration(
                    color: isVisible.value
                        ? null
                        : Get.isDarkMode
                            ? AppTheme.colorDark
                            : Colors.black,
                  ),
                  child: canTap
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (isVisible.value && link != null) {
                                parseUrl(url: link, poUserHash: poUserHash);
                              } else {
                                isVisible.value = !isVisible.value;
                              }
                            },
                            child: textWidget,
                          ),
                        )
                      : textWidget,
                );
              },
            ),
          );
        },
        textStyle: textStyle,
      ),
    ],
  );
}
