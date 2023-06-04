import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/blacklist.dart';
import '../data/services/settings.dart';
import 'image.dart';
import 'regex.dart';

const int _int32Max = 4294967295;

const int imageHashLength = 20;

const int _imageNameHashLength = 13;

const int _normalPostIdPrefix = 0;

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
  /// “No.xxx”形式
  String toPostNumber() => 'No.$this';

  /// “>>No.xxx”形式
  String toPostReference() => '>>${toPostNumber()}';

  int postIdToPostIndex(int page) => (page << 32) | this;

  int get pageFromPostIndex => this >>> 32;

  int get postIdFromPostIndex => this & _int32Max;

  int get postMaxPage => this > 0 ? (this / 19).ceil() : 1;

  bool get isNormalPost => (this >>> 32) == _normalPostIdPrefix;

  bool get isPostHistory => (this >>> 32) == PostData.taggedPostIdPrefix;

  bool get isReplyHistory => (this >>> 32) == ReplyData.taggedPostIdPrefix;

  int? get postId => isNormalPost ? this : null;

  int? get historyId =>
      (isPostHistory || isReplyHistory) ? this & _int32Max : null;
}

extension IntNullExtension on int? {
  int? get notNegative => this != null ? max(this!, 0) : null;

  TextOverflow get textOverflow =>
      this != null ? TextOverflow.ellipsis : TextOverflow.clip;
}

extension PostExtension on PostBase {
  /// “No.xxx”形式
  String toPostNumber() => id.toPostNumber();

  /// “>>No.xxx”形式
  String toPostReference() => id.toPostReference();

  int toIndex(int page) => id.postIdToPostIndex(page);

  ValueKey<int> toValueKey(int page) => ValueKey<int>(toIndex(page));

  bool isBlocked() {
    final blacklist = BlacklistService.to;

    return !isAdmin && (blacklist.hasPost(id) || blacklist.hasUser(userHash));
  }

  String? get thumbImageKey =>
      hasImage ? hashImage('thumb/$imageFile', imageHashLength) : null;

  String? get imageKey =>
      hasImage ? hashImage('image/$imageFile', imageHashLength) : null;

  String? imageHashFileName() {
    if (hasImage) {
      final imageName = imageFile!;
      final hash = hashImage(imageName, _imageNameHashLength);

      return (Regex.replaceImageHash(imageName: imageName, hash: hash)
              ?.replaceAll('/', '-')) ??
          hash;
    }

    return null;
  }

  bool get isNormalPost => id.isNormalPost;

  bool get isPostHistory => id.isPostHistory;

  bool get isReplyHistory => id.isReplyHistory;

  int? get postId => id.postId;

  int? get historyId => id.historyId;
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

extension TextStyleNullExtension on TextStyle? {
  /// 主要是在富文本中使用
  StrutStyle? get sameHeightStrutStyle =>
      this?.height != null ? StrutStyle(height: this!.height) : null;
}
