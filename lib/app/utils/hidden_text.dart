import 'dart:collection';

import 'package:flutter/material.dart' hide Element;
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';

import 'regex.dart';
import 'theme.dart';
import 'url.dart';

Map<String, OnTagCallback> onHiddenTag(OnTagCallback onHiddenText) =>
    HashMap.fromEntries([MapEntry('h', onHiddenText)]);

// TODO: 重构隐藏文字
InlineSpan onHiddenText(
    {required BuildContext context,
    required Element element,
    required TextStyle textStyle,
    Color? hiddenColor,
    bool canTap = false,
    int? mainPostId,
    String? poUserHash}) {
  final isVisible = false.obs;

  return TextSpan(
    children: [
      htmlToTextSpan(
        context,
        element.innerHtml,
        onText: (context, text) => Regex.onText(text),
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
                              ..color = hiddenColor ??
                                  (Get.isDarkMode
                                      ? AppTheme.colorDark
                                      : Colors.black),
                          ),
                  ),
                );

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: isVisible.value
                        ? null
                        : hiddenColor ??
                            (Get.isDarkMode
                                ? AppTheme.colorDark
                                : Colors.black),
                  ),
                  child: canTap
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (isVisible.value && link != null) {
                                parseUrl(
                                    url: link,
                                    mainPostId: mainPostId,
                                    poUserHash: poUserHash);
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
