import 'package:flutter/material.dart';

import '../routes/routes.dart';
import 'extensions.dart';

abstract class Regex {
  static const _postReference1 = r'(?:&gt;)*No\.([0-9]+)';

  static const _postReference2 = r'(?:&gt;)+([0-9]+)';

  static const _postId = r'(^[0-9]+$)';

  static const _postReference3 = r'(?:>)*No\.([0-9]+)';

  static const _postReference4 = r'(?:>)+([0-9]+)';

  static const _hasHiddenTag = r'\[h\].+\[\/h\]';

  static const _hiddenTag = r'(\[h\])|(\[\/h\])';

  static final RegExp _postRegex = RegExp('$_postReference1|$_postReference2');

  static final RegExp _postIdRegex =
      RegExp('$_postId|$_postReference3|$_postReference4');

  static final RegExp _hasHiddenTagRegex = RegExp(_hasHiddenTag, dotAll: true);

  static final RegExp _hiddenTagRegex = RegExp(_hiddenTag);

  static String? replaceHiddenTag(String text) {
    if (text.contains(_hasHiddenTagRegex)) {
      try {
        return _parseHiddenTag(text);
      } catch (e) {
        debugPrint('解析隐藏文字tag时出现错误：$e');
      }
    }

    return null;
  }

  static String? onReference(String text) {
    var isReplaced = false;

    text = text.replaceAllMapped(_postRegex, (match) {
      isReplaced = true;
      final id = match[1] ?? match[2];

      return id != null
          ? '<a href="${AppRoutes.referenceUrl(int.parse(id))}" '
              'style="color:#789922;">${match[0]}</a>'
          : match[0]!;
    });

    if (isReplaced) {
      return text;
    }

    return null;
  }

  static int? getPostId(String text) {
    final match = _postIdRegex.firstMatch(text);
    if (match != null) {
      final postId = match[1] ?? match[2] ?? match[3];

      return postId.tryParseInt();
    }

    return null;
  }
}

String _parseHiddenTag(String text) {
  final List<int> leftHiddenTags = [];
  final List<int> rightHiddenTags = [];

  for (final match in Regex._hiddenTagRegex.allMatches(text)) {
    if (match[1] != null) {
      leftHiddenTags.add(match.start);
    }
    if (match[2] != null) {
      rightHiddenTags.add(match.start);
    }
  }

  var left = 0;
  var right = 0;
  while (left < leftHiddenTags.length && right < rightHiddenTags.length) {
    if (rightHiddenTags[right] < leftHiddenTags[left]) {
      final nextRightIndex = rightHiddenTags
          .indexWhere((position) => position > leftHiddenTags[left]);
      if (nextRightIndex < 0) {
        break;
      }
      right = nextRightIndex;
      continue;
    }

    if (left == leftHiddenTags.length - 1 ||
        right == rightHiddenTags.length - 1) {
      text = text
          ._replaceLeft(leftHiddenTags[left])
          ._replaceRight(rightHiddenTags[rightHiddenTags.length - 1]);
      break;
    }

    final nextLeftIndex = leftHiddenTags
        .indexWhere((position) => position > rightHiddenTags[right]);
    if (nextLeftIndex < 0) {
      text = text
          ._replaceLeft(leftHiddenTags[left])
          ._replaceRight(rightHiddenTags[rightHiddenTags.length - 1]);
      break;
    }
    if (rightHiddenTags[right + 1] < leftHiddenTags[nextLeftIndex]) {
      final nextRightIndex = rightHiddenTags
          .indexWhere((position) => position > leftHiddenTags[nextLeftIndex]);
      if (nextRightIndex < 0) {
        text = text
            ._replaceLeft(leftHiddenTags[left])
            ._replaceRight(rightHiddenTags[rightHiddenTags.length - 1]);
        break;
      }
      right = nextRightIndex - 1;
      continue;
    }

    text = text
        ._replaceLeft(leftHiddenTags[left])
        ._replaceRight(rightHiddenTags[right]);
    left = nextLeftIndex;
    right++;
  }

  return text;
}

extension _Replace on String {
  String _replaceLeft(int index) => replaceRange(index, index + 3, '<h>');

  String _replaceRight(int index) => replaceRange(index, index + 4, '</h>');
}
