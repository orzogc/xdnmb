import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../utils/text.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'tag.dart';

class ForumNameText extends StatelessWidget {
  final String forumName;

  final String? leading;

  final String? trailing;

  final TextStyle? textStyle;

  final int? maxLines;

  const ForumNameText(
      {super.key,
      required this.forumName,
      this.leading,
      this.trailing,
      this.textStyle,
      this.maxLines});

  @override
  Widget build(BuildContext context) => (leading != null || trailing != null)
      ? RichText(
          text: TextSpan(
            children: [
              if (leading != null) TextSpan(text: leading, style: textStyle),
              htmlToTextSpan(context, forumName, textStyle: textStyle),
              if (trailing != null) TextSpan(text: trailing, style: textStyle),
            ],
            style: textStyle,
          ),
          maxLines: maxLines,
          overflow:
              maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
          strutStyle: strutStyleFromHeight(textStyle),
        )
      : RichText(
          text: htmlToTextSpan(context, forumName, textStyle: textStyle),
          maxLines: maxLines,
          overflow:
              maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
          strutStyle: strutStyleFromHeight(textStyle),
        );
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
      this.maxLines})
      : assert(isDeprecated == null || (leading == null && trailing == null));

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return ListenableBuilder(
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
                maxLines: maxLines)
            : (fallbackText != null
                ? Text(fallbackText!,
                    style: textStyle,
                    strutStyle: textStyle != null
                        ? StrutStyle.fromTextStyle(textStyle!)
                        : null,
                    maxLines: maxLines,
                    overflow: maxLines != null
                        ? TextOverflow.ellipsis
                        : TextOverflow.clip)
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
        decoration: const InputDecoration(labelText: '版块名字'),
        autofocus: true,
        validator: (value) =>
            (value == null || value.isEmpty) ? '请输入版块名字' : null,
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
