import 'package:flutter/material.dart';

import '../data/models/controller.dart';
import '../utils/theme.dart';

class TightListTile extends ListTile {
  const TightListTile(
      {super.key,
      super.enabled,
      super.leading,
      super.title,
      super.subtitle,
      super.trailing,
      super.onTap,
      super.onLongPress})
      : super(
            contentPadding: EdgeInsets.zero,
            visualDensity:
                const VisualDensity(vertical: VisualDensity.minimumDensity));
}

class TightCheckboxListTile extends CheckboxListTile {
  const TightCheckboxListTile(
      {super.key,
      super.enabled,
      super.title,
      super.subtitle,
      required super.value,
      required super.onChanged})
      : super(
            contentPadding: EdgeInsets.zero,
            visualDensity:
                const VisualDensity(vertical: VisualDensity.minimumDensity));
}

class SearchListTile extends StatelessWidget {
  final Search search;

  final VoidCallback? onCancel;

  const SearchListTile({super.key, required this.search, this.onCancel});

  @override
  Widget build(BuildContext context) => TightListTile(
        title: Center(
          child: Text.rich(
            TextSpan(
              text: '搜索内容：',
              children: [
                TextSpan(
                  text: search.text,
                  style: AppTheme.boldRed,
                ),
              ],
            ),
          ),
        ),
        subtitle: (search.caseSensitive || search.useWildcard)
            ? Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 5.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (search.caseSensitive) const Text('英文字母区分大小写'),
                  if (search.useWildcard) const Text('使用通配符'),
                ],
              )
            : null,
        trailing: onCancel != null
            ? IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
              )
            : const SizedBox.shrink(),
      );
}
