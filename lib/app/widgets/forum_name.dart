import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../utils/extensions.dart';
import '../utils/theme.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'tag.dart';

class _ForumName {
  final String forumName;

  final bool isDarkMode;

  const _ForumName(this.forumName, this.isDarkMode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ForumName &&
          forumName == other.forumName &&
          isDarkMode == other.isDarkMode);

  @override
  int get hashCode => Object.hash(forumName, isDarkMode);
}

abstract class _ForumNameCache {
  static final HashMap<_ForumName, TextSpan> _bodyLarge = HashMap();

  static final HashMap<String, TextSpan> _bodySmallWithHeaderColor = HashMap();
}

enum ForumNameStyle {
  bodyLarge,
  bodySmallWithHeaderColor;

  TextSpan _getForumName(BuildContext context, String forumName) {
    switch (this) {
      case bodyLarge:
        final key = _ForumName(forumName, Get.isDarkMode);
        final text = _ForumNameCache._bodyLarge[key];
        if (text == null) {
          final span = htmlToTextSpan(context, forumName,
              textStyle: Theme.of(context).textTheme.bodyLarge);
          _ForumNameCache._bodyLarge[key] = span;

          return span;
        } else {
          return text;
        }
      case bodySmallWithHeaderColor:
        final text = _ForumNameCache._bodySmallWithHeaderColor[forumName];
        if (text == null) {
          final span = htmlToTextSpan(context, forumName,
              textStyle: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.apply(color: AppTheme.headerColor));
          _ForumNameCache._bodySmallWithHeaderColor[forumName] = span;

          return span;
        } else {
          return text;
        }
    }
  }
}

class ForumNameText extends StatelessWidget {
  final String forumName;

  final String? leading;

  final String? trailing;

  final TextStyle? textStyle;

  final int? maxLines;

  final ForumNameStyle? forumNameCache;

  const ForumNameText(
      {super.key,
      required this.forumName,
      this.leading,
      this.trailing,
      this.textStyle,
      this.maxLines,
      this.forumNameCache})
      : assert(forumNameCache == null || textStyle == null);

  @override
  Widget build(BuildContext context) {
    final span = forumNameCache?._getForumName(context, forumName) ??
        htmlToTextSpan(context, forumName, textStyle: textStyle);

    return (leading != null || trailing != null)
        ? RichText(
            text: TextSpan(
              children: [
                if (leading != null) TextSpan(text: leading, style: textStyle),
                span,
                if (trailing != null)
                  TextSpan(text: trailing, style: textStyle),
              ],
              style: textStyle,
            ),
            maxLines: maxLines,
            overflow: maxLines.textOverflow,
            strutStyle: textStyle.sameHeightStrutStyle,
          )
        : RichText(
            text: span,
            maxLines: maxLines,
            overflow: maxLines.textOverflow,
            strutStyle: textStyle.sameHeightStrutStyle,
          );
  }
}

class ForumName extends StatelessWidget {
  final int forumId;

  final bool isTimeline;

  final bool isDisplay;

  final bool? isDeprecated;

  final String? leading;

  final String? trailing;

  final String? fallbackText;

  final TextStyle? textStyle;

  final int? maxLines;

  final ForumNameStyle? forumNameCache;

  const ForumName(
      {super.key,
      required this.forumId,
      this.isTimeline = false,
      this.isDisplay = true,
      this.isDeprecated,
      this.leading,
      this.trailing,
      this.fallbackText,
      this.textStyle,
      this.maxLines,
      this.forumNameCache})
      : assert(isDeprecated == null || (leading == null && trailing == null));

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return ListenBuilder(
      listenable: forums.updateForumNameNotifier,
      builder: (context, child) {
        final name = forums.forumName(forumId,
            isTimeline: isTimeline, isDisplay: isDisplay);
        final Widget nameWidget = name != null
            ? ForumNameText(
                forumName: name,
                leading: leading,
                trailing: trailing,
                textStyle: textStyle,
                maxLines: maxLines,
                forumNameCache: forumNameCache)
            : (fallbackText != null
                ? Text(fallbackText!,
                    style: textStyle,
                    strutStyle: textStyle != null
                        ? StrutStyle.fromTextStyle(textStyle!)
                        : null,
                    maxLines: maxLines,
                    overflow: maxLines.textOverflow)
                : const SizedBox.shrink());

        return (isDeprecated ?? false)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: nameWidget),
                  Tag(
                      text: '隐藏',
                      textStyle: Theme.of(context).textTheme.bodySmall),
                ],
              )
            : nameWidget;
      },
    );
  }
}

class EditForumName extends StatefulWidget {
  final ForumData forum;

  const EditForumName({super.key, required this.forum});

  @override
  State<EditForumName> createState() => _EditForumNameState();
}

class _EditForumNameState extends State<EditForumName> {
  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.forum.forumDisplayName);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return InputDialog(
      content: TextFormField(
        key: _formKey,
        controller: _controller,
        decoration: InputDecoration(
            labelText: widget.forum.isTimeline ? '时间线名字' : '版块名字'),
        autofocus: true,
        validator: (value) => (value == null || value.isEmpty)
            ? '请输入${widget.forum.isTimeline ? '时间线' : '版块'}名字'
            : null,
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (mounted) {
              setState(() => _controller.text = widget.forum.showName);
            }
          },
          child: const Text('默认名字'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await forums.setForumName(widget.forum, _controller.text);
              Get.back(result: true);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class SelectForum extends StatelessWidget {
  final bool isOnlyForum;

  /// 选取版块时调用，参数是版块数据
  final ValueSetter<ForumData> onSelect;

  const SelectForum(
      {super.key, this.isOnlyForum = false, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to.forums;

    return SimpleDialog(
      children: [
        for (final forum
            in isOnlyForum ? forums.where((forum) => forum.isForum) : forums)
          SimpleDialogOption(
            onPressed: () => onSelect(forum),
            child: ForumName(
              forumId: forum.id,
              isTimeline: forum.isTimeline,
              isDeprecated: forum.isDeprecated,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}
