import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/blacklist.dart';
import '../data/services/settings.dart';
import 'image.dart';
import 'regex.dart';

const int _int32Max = 4294967295;

const int imageHashLength = 20;

const int _imageNameHashLength = 13;

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

  int postIdToPostIndex(int page) => page << 32 | this;

  int getPageFromPostIndex() => this >>> 32;

  int getPostIdFromPostIndex() => this & _int32Max;
}

extension PostExtension on PostBase {
  String toPostNumber() => id.toPostNumber();

  String toPostReference() => id.toPostReference();

  int toIndex(int page) => id.postIdToPostIndex(page);

  ValueKey<int> toValueKey(int page) => ValueKey<int>(toIndex(page));

  bool isBlocked() {
    final blacklist = BlacklistService.to;

    return !isAdmin && (blacklist.hasPost(id) || blacklist.hasUser(userHash));
  }

  String? thumbImageKey() =>
      hasImage() ? hashImage('thumb/${imageFile()}', imageHashLength) : null;

  String? imageKey() =>
      hasImage() ? hashImage('image/${imageFile()}', imageHashLength) : null;

  String? imageHashFileName() {
    if (hasImage()) {
      final imageName = imageFile()!;
      final hash = hashImage(imageName, _imageNameHashLength);

      return (Regex.replaceImageHash(imageName: imageName, hash: hash)
              ?.replaceAll('/', '-')) ??
          hash;
    }

    return null;
  }
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

extension ImageTypeExtension on ImageType {
  String extension() {
    switch (this) {
      case ImageType.jpeg:
        return 'jpg';
      case ImageType.png:
        return 'png';
      case ImageType.gif:
        return 'gif';
    }
  }
}

extension GetExtension on GetInterface {
  void maybePop<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int? id,
  }) {
    if (isSnackbarOpen && !closeOverlays) {
      closeCurrentSnackbar();
      return;
    }

    if (closeOverlays && isOverlaysOpen) {
      if (isSnackbarOpen) {
        closeAllSnackbars();
      }
      navigator?.popUntil((route) {
        return (!isDialogOpen! && !isBottomSheetOpen!);
      });
    }
    if (canPop) {
      if (global(id).currentState?.canPop() == true) {
        global(id).currentState?.maybePop<T>(result);
      }
    } else {
      global(id).currentState?.maybePop<T>(result);
    }
  }

  Future<T?>? push<T>(Route<T> route, [int? id]) =>
      Get.global(id).currentState?.push<T>(route);
}

extension DateTimeExtension on DateTime {
  DateTime addOneDay() => add(const Duration(days: 1));
}

extension FontWeightExtension on FontWeight {
  int toInt() => index + 1;

  int toCssStyle() => toInt() * 100;

  static FontWeight fromInt(int n) {
    if (n < SettingsService.minFontWeight ||
        n > SettingsService.maxFontWeight) {
      return FontWeight.normal;
    }

    return FontWeight.values[n - 1];
  }
}
