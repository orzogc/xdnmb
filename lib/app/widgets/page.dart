import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import 'dialog.dart';

class _JumpPageDialog extends StatefulWidget {
  final int currentPage;

  final int? maxPage;

  const _JumpPageDialog({super.key, required this.currentPage, this.maxPage});

  @override
  State<_JumpPageDialog> createState() => _JumpPageDialogState();
}

class _JumpPageDialogState extends State<_JumpPageDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: '${widget.currentPage}');
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputDialog(
      title: const Text('跳页'),
      content: Form(
        key: _formKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () => _controller.text = '1',
                icon: const Icon(Icons.first_page)),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final num = value.tryParseInt();
                  if (num == null ||
                      (widget.maxPage != null && num > widget.maxPage!)) {
                    return '请输入页数';
                  }

                  return null;
                },
              ),
            ),
            if (widget.maxPage != null) const Text('/'),
            if (widget.maxPage != null) Text('${widget.maxPage}'),
            IconButton(
              onPressed: () {
                if (widget.maxPage != null) {
                  _controller.text = '${widget.maxPage}';
                } else {
                  final page = _controller.text.tryParseInt();
                  if (page != null) {
                    _controller.text = '${page + 10}';
                  }
                }
              },
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              postListBack<int>(result: int.tryParse(_controller.text));
            }
          },
          child: const Text('确定'),
        )
      ],
    );
  }
}

class PageButton extends StatefulWidget {
  final PostListController controller;

  final int? maxPage;

  const PageButton({super.key, required this.controller, this.maxPage});

  @override
  State<PageButton> createState() => _PageButtonState();
}

class _PageButtonState extends State<PageButton> {
  bool isShowDialog = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () async {
        if (!isShowDialog) {
          isShowDialog = true;
          try {
            final page = await postListDialog<int>(_JumpPageDialog(
                currentPage: widget.controller.currentPage.value,
                maxPage: widget.maxPage));
            if (page != null) {
              widget.controller.refreshPage(page);
            }
          } finally {
            isShowDialog = false;
          }
        }
      },
      child: Obx(
        () => Text(
          '${widget.controller.currentPage.value}',
          style: theme.textTheme.headline6?.apply(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

/* class PageButton extends StatelessWidget {
  final PostListController controller;

  final int? maxPage;

  const PageButton({super.key, required this.controller, this.maxPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isShowDialog = false;

    return TextButton(
      onPressed: () async {
        if (!isShowDialog) {
          isShowDialog = true;
          try {
            final page = await postListDialog<int>(_JumpPageDialog(
                currentPage: controller.currentPage.value, maxPage: maxPage));
            if (page != null) {
              controller.refreshPage(page);
            }
          } finally {
            isShowDialog = false;
          }
        }
      },
      child: Obx(
        () => Text(
          '${controller.currentPage.value}',
          style: theme.textTheme.headline6
              ?.apply(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }
} */
