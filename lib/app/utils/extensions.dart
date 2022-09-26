import 'package:flutter/material.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

const int _int32Max = 4294967295;

extension ParseStringExtension on String? {
  int? tryParseInt() => this != null ? int.tryParse(this!) : null;

  bool? tryParseBool() =>
      this == 'true' ? true : (this == 'false' ? false : null);
}

extension WidgetListExtension on List<Widget> {
  List<Widget> withSpaceBetween({double? width, double? height}) => [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: width, height: height),
          this[i],
        ],
      ];

  List<Widget> withDividerBetween({double? height, double? thickness}) => [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) Divider(height: height, thickness: thickness),
          this[i],
        ],
      ];
}

extension IntExtension on int {
  String toPostNumber() => 'No.$this';

  String toPostReference() => '>>${toPostNumber()}';

  int toIndex(int page) => page << 32 | this;

  int getPageFromIndex() => this >>> 32;

  int getIdFromIndex() => this & _int32Max;
}

extension PostExtension on PostBase {
  String toPostNumber() => id.toPostNumber();

  String toPostReference() => id.toPostReference();

  int toIndex(int page) => id.toIndex(page);

  ValueKey<int> toValueKey(int page) => ValueKey<int>(toIndex(page));
}

extension TextEditingControllerExtension on TextEditingController {
  void insertText(String text, [int? offset]) {
    final cursor = selection.baseOffset;

    if (cursor < 0) {
      value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: offset ?? text.length));
    } else {
      final newText =
          this.text.replaceRange(selection.start, selection.end, text);
      value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: cursor + (offset ?? text.length)));
    }
  }
}
