import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import 'dialog.dart';

Widget forumNameText(BuildContext context, String forumName,
        {String? leading,
        String? trailing,
        TextStyle? textStyle,
        int? maxLines,
        TextOverflow overflow = TextOverflow.ellipsis}) =>
    (leading != null || trailing != null)
        ? RichText(
            text: TextSpan(
              children: [
                if (leading != null) TextSpan(text: leading, style: textStyle),
                htmlToTextSpan(context, forumName, textStyle: textStyle),
                if (trailing != null)
                  TextSpan(text: trailing, style: textStyle),
              ],
              style: textStyle,
            ),
            overflow: overflow,
            maxLines: maxLines,
          )
        : RichText(
            text: htmlToTextSpan(context, forumName, textStyle: textStyle),
            overflow: overflow,
            maxLines: maxLines,
          );

class ForumName extends StatelessWidget {
  final int forumId;

  final bool isTimeline;

  final int? maxLines;

  const ForumName(
      {super.key,
      required this.forumId,
      this.isTimeline = false,
      this.maxLines});

  @override
  Widget build(BuildContext context) {
    final name = ForumListService.to.forumName(forumId, isTimeline: isTimeline);

    return name != null
        ? forumNameText(context, name, maxLines: maxLines)
        : const SizedBox.shrink();
  }
}

class EditForumName extends StatefulWidget {
  final ForumData forum;

  const EditForumName({super.key, required this.forum});

  @override
  State<EditForumName> createState() => _EditForumNameState();
}

class _EditForumNameState extends State<EditForumName> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.forum.forumName);
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
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(labelText: '板块名字'),
          autofocus: true,
          validator: (value) =>
              (value == null || value.isEmpty) ? '请输入板块名字' : null,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final forumName = widget.forum.showName;
            await widget.forum.editUserDefinedName(forumName);
            forums.isReady.refresh();
            if (mounted) {
              setState(() => _controller.text = forumName);
            }
          },
          child: const Text('恢复默认名字'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              await widget.forum.editUserDefinedName(_controller.text);
              forums.isReady.refresh();
              Get.back(result: true);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

typedef ForumCallback = void Function(ForumData forum);

class SelectForum extends StatelessWidget {
  final bool isOnlyForum;

  final ForumCallback onSelect;

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
            child: forumNameText(
              context,
              forum.forumName,
              textStyle: Theme.of(context).textTheme.bodyText1,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}
