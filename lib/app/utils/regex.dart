import 'package:flutter/material.dart';

import '../data/models/controller.dart';
import '../routes/routes.dart';
import 'extensions.dart';
import 'theme.dart';

abstract class Regex {
  static const String _postReference1 = r'(?:&gt;)*No\.([0-9]+)';

  static const String _postReference2 = r'(?:&gt;)+([0-9]+)';

  static const String _postReference3 = r'([0-9]{8,})';

  static const String _link =
      r'((?:https?:\/\/)*(?:www\.){0,1}nmbxd[0-9]*\.com\/f\/[^ ]{1,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[a-zA-Z]{2,}[-a-zA-Z0-9@%_+.~#?&/=|:;]*|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[a-zA-Z]{2,}[-a-zA-Z0-9@%_+.~#?&/=|:;]*|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[a-zA-Z]{2,}[-a-zA-Z0-9@%_+.~#?&/=|:;]*|www\.[a-zA-Z0-9]+\.[a-zA-Z]{2,}[-a-zA-Z0-9@%_+.~#?&/=|:;]*)';

  static const String _postId = r'(^[0-9]+$)';

  static const String _postReference4 = r'(?:>)*No\.([0-9]+)';

  static const String _postReference5 = r'(?:>)+([0-9]+)';

  static const String _hasHiddenTag = r'\[h\].+\[\/h\]';

  static const String _hiddenTag = r'(\[h\])|(\[\/h\])';

  static const String _xdnmbHost = r'^(?:www\.){0,1}nmbxd[0-9]*\.com$';

  static const String _xdnmbHtml = r'(.+)(?=\.html$)|(.+)';

  static const String _escape = r'[/\-\\^$*+?.()|[\]{}]';

  static const String _imageHash = r'(?<=\/)(?:.+(?=\.)|.+)';

  static final RegExp _textRegex =
      RegExp('$_postReference1|$_postReference2|$_postReference3|$_link');

  static final RegExp _postIdRegex =
      RegExp('$_postId|$_postReference4|$_postReference5');

  static final RegExp _hasHiddenTagRegex = RegExp(_hasHiddenTag, dotAll: true);

  static final RegExp _hiddenTagRegex = RegExp(_hiddenTag);

  static final RegExp _xdnmbHostRegex = RegExp(_xdnmbHost);

  static final RegExp _xdnmbHtmlRegex = RegExp(_xdnmbHtml);

  static final RegExp _escapeRegex = RegExp(_escape);

  static final RegExp _imageHashRegex = RegExp(_imageHash);

  static String? replaceHiddenTag(String text) {
    if (text.contains(_hasHiddenTagRegex)) {
      try {
        return _parseHiddenTag(text);
      } catch (e) {
        debugPrint('解析隐藏文字tag时出错：$e');
      }
    }

    return null;
  }

  static String? onText(String text) {
    bool isReplaced = false;

    text = text.replaceAllMapped(_textRegex, (match) {
      isReplaced = true;
      String? id = match[1] ?? match[2];

      // 纯数字只有大于50000000才算是串号
      if (id == null) {
        final n = match[3];
        if (n != null && int.parse(n) >= 50000000) {
          id = n;
        }
      }

      final link = match[4];

      return id != null
          ? '<a href="${AppRoutes.referenceUrl(int.parse(id))}" '
              'style="color:#789922;">${match[0]}</a>'
          : (link != null ? '<a href="$link">${match[0]}</a>' : match[0]!);
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

  static bool isXdnmbHost(String text) => _xdnmbHostRegex.hasMatch(text);

  static String? getXdnmbParameter(String text) {
    final match = _xdnmbHtmlRegex.firstMatch(text);

    return match?[1] ?? match?[2];
  }

  static String? onSearchText({required String text, required Search search}) {
    final searchText =
        search.text.replaceAllMapped(_escapeRegex, (match) => '\\${match[0]}');

    bool isReplaced = false;

    text = text.replaceAllMapped(
        RegExp(searchText, caseSensitive: search.caseSensitive), (match) {
      isReplaced = true;

      return '<span style="color:red;font-weight:${AppTheme.postContentBoldFontWeight.toCssStyle()}">${match[0]}</span>';
    });

    if (isReplaced) {
      return text;
    }

    return null;
  }

  static String? replaceImageHash(
      {required String imageName, required String hash}) {
    bool isReplaced = false;

    imageName = imageName.replaceFirstMapped(_imageHashRegex, (match) {
      isReplaced = true;

      return hash;
    });

    if (isReplaced) {
      return imageName;
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

  int left = 0;
  int right = 0;
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
