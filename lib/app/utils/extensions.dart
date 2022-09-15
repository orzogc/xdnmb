import 'package:flutter/material.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

extension ParseStringExtension on String? {
  int? tryParseInt() => this != null ? int.tryParse(this!) : null;
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
}

extension PostExtension on PostBase {
  String toPostNumber() => id.toPostNumber();

  String toPostReference() => id.toPostReference();

  ValueKey<int> toValueKey(int index) => ValueKey<int>(index << 32 | id);
}
