import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../data/services/tag.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/icons.dart';
import '../utils/navigation.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'dialog.dart';
import 'reference.dart';
import 'size.dart';

class _Button extends StatelessWidget {
  final Widget icon;

  final String label;

  final VoidCallback onTap;

  const _Button(
      // ignore: unused_element
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: icon, title: Text(label), onTap: onTap);
}

class DarkModeButton extends StatelessWidget {
  static const Widget _whiteIcon = Icon(Icons.sunny, color: Colors.white);

  static const Widget _blackIcon =
      Icon(Icons.brightness_3, color: Colors.black);

  final bool showLabel;

  const DarkModeButton({super.key, this.showLabel = false});

  void _onTap() {
    final settings = SettingsService.to;

    settings.isDarkMode = !settings.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() {
      // 确保模式完全改变后再重建
      settings.hasBeenDarkMode.value;

      return showLabel
          ? _Button(
              icon: Get.isDarkMode ? _whiteIcon : _blackIcon,
              label: Get.isDarkMode ? '光来' : '暗来',
              onTap: _onTap,
            )
          : IconButton(
              onPressed: _onTap,
              tooltip: Get.isDarkMode ? '光来！' : '暗来！',
              icon: Get.isDarkMode ? _whiteIcon : _blackIcon,
            );
    });
  }
}

// 修改自官方代码
class _AutocompleteOptions extends StatelessWidget {
  static const double _maxHeight = 200.0;

  const _AutocompleteOptions({
    // ignore: unused_element
    super.key,
    required this.maxWidth,
    required this.options,
    required this.onSelected,
  });

  final double maxWidth;

  final List<String> options;

  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightIndex = AutocompleteHighlightedOption.of(context);

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: maxWidth, maxHeight: _maxHeight),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];

              return InkWell(
                onTap: () => onSelected(option),
                child: Builder(builder: (context) {
                  final bool highlight = highlightIndex == index;
                  if (highlight) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) =>
                        Scrollable.ensureVisible(context, alignment: 0.5));
                  }

                  return Container(
                    color: highlight ? theme.focusColor : null,
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatelessWidget {
  static const int _searchIndex = 0;

  static const int _postIdIndex = 1;

  static const int _tagIndex = 2;

  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  final RxInt _index = _postIdIndex.obs;

  final Iterable<String> _allTagsName =
      TagService.to.allTagsData.map((tag) => tag.name.toLowerCase());

  // ignore: unused_element
  _SearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;
    String? content;
    double width = 0.0;

    return InputDialog(
      title: const Text('查询'),
      content: Obx(
        () => Row(
          children: [
            DropdownButton<int>(
              value: _index.value,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  _index.value = value;
                }
              },
              items: const [
                DropdownMenuItem(
                  value: _searchIndex,
                  enabled: false,
                  child: Tooltip(
                    message: '搜索坏了',
                    child: Text('搜索', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                DropdownMenuItem(
                  value: _postIdIndex,
                  child: Text('串号'),
                ),
                DropdownMenuItem(
                  value: _tagIndex,
                  child: Text('标签'),
                ),
              ],
            ),
            const SizedBox(width: 5.0),
            Flexible(
              child: Autocomplete<String>(
                key: ValueKey<int>(_index.value),
                initialValue: TextEditingValue(text: content ?? ''),
                optionsBuilder: (textEditingValue) {
                  if (_index.value == _tagIndex) {
                    if (textEditingValue.text.isNotEmpty) {
                      final text = textEditingValue.text.toLowerCase();

                      return _allTagsName.where((name) => name.contains(text));
                    } else {
                      return _allTagsName;
                    }
                  }

                  return [];
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                        onFieldSubmitted) =>
                    ChildSizeNotifier(
                  builder: (context, size, child) {
                    width = size.width;

                    return child!;
                  },
                  child: TextFormField(
                    key: _formKey,
                    controller: textEditingController,
                    focusNode: focusNode,
                    autofocus: true,
                    onChanged: (value) => content = value,
                    onFieldSubmitted: (value) => onFieldSubmitted(),
                    onSaved: (newValue) => content = newValue,
                    validator: (value) => (value == null || value.isEmpty)
                        ? '请输入查询内容'
                        : (_index.value == _postIdIndex
                            ? (Regex.getPostId(value) == null
                                ? '请输入串号或串号引用'
                                : null)
                            : (_index.value == _tagIndex
                                ? (!tagService.tagNameExists(value)
                                    ? '标签不存在'
                                    : null)
                                : null)),
                  ),
                ),
                optionsViewBuilder: (context, onSelected, options) =>
                    _AutocompleteOptions(
                  maxWidth: width,
                  options: options.toList(),
                  onSelected: onSelected,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              switch (_index.value) {
                case _searchIndex:
                  showToast('暂不支持搜索');

                  return;
                case _postIdIndex:
                  final postId = Regex.getPostId(content!);
                  if (postId != null) {
                    Get.back<bool>(result: true);
                    postListDialog(
                        Center(child: ReferenceCard(postId: postId)));

                    return;
                  } else {
                    showToast('请输入串号');
                  }

                  return;
                case _tagIndex:
                  final tag = tagService.getTagDataFromName(content!);
                  if (tag != null) {
                    Get.back<bool>(result: true);
                    AppRoutes.toTaggedPostList(tagId: tag.id);

                    return;
                  } else {
                    showToast('标签 $content 不存在');
                  }

                  return;
                default:
                  debugPrint('未知的查询选项：${_index.value}');
              }
            }
          },
          child: const Text('查询'),
        ),
      ],
    );
  }
}

class SearchButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final EdgeInsetsGeometry? iconPadding;

  final VoidCallback? onTapPrelude;

  final VoidCallback? afterSearch;

  const SearchButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.iconPadding,
      this.onTapPrelude,
      this.afterSearch});

  Future<void> _onTap() async {
    onTapPrelude?.call();

    final result = await Get.dialog<bool>(_SearchDialog());
    if (result ?? false) {
      afterSearch?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.search, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '查询', onTap: _onTap)
        : IconButton(
            padding: iconPadding, onPressed: _onTap, tooltip: '查询', icon: icon);
  }
}

class SettingsButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final EdgeInsetsGeometry? iconPadding;

  final VoidCallback? onTapPrelude;

  const SettingsButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.iconPadding,
      this.onTapPrelude});

  void _onTap() {
    onTapPrelude?.call();
    AppRoutes.toSettings();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.settings, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '设置', onTap: _onTap)
        : IconButton(
            padding: iconPadding, onPressed: _onTap, tooltip: '设置', icon: icon);
  }
}

class HistoryButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final EdgeInsetsGeometry? iconPadding;

  final VoidCallback? onTapPrelude;

  final VoidCallback? onTapEnd;

  const HistoryButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.iconPadding,
      this.onTapPrelude,
      this.onTapEnd});

  void _onTap() {
    onTapPrelude?.call();

    if (PostListController.get().isHistory) {
      postListBack();
    } else {
      AppRoutes.toHistory();
    }

    onTapEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.history, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '历史', onTap: _onTap)
        : IconButton(
            padding: iconPadding, onPressed: _onTap, tooltip: '历史', icon: icon);
  }
}

class FeedButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final EdgeInsetsGeometry? iconPadding;

  final VoidCallback? onTapPrelude;

  final VoidCallback? onTapEnd;

  const FeedButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.iconPadding,
      this.onTapPrelude,
      this.onTapEnd});

  void _onTap() {
    onTapPrelude?.call();

    if (PostListController.get().isFeed) {
      postListBack();
    } else {
      AppRoutes.toFeed();
    }

    onTapEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.rss_feed, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '订阅', onTap: _onTap)
        : IconButton(
            padding: iconPadding,
            onPressed: _onTap,
            tooltip: '订阅/标签',
            icon: icon);
  }
}

class _SponsorDialog extends StatelessWidget {
  // ignore: unused_element
  const _SponsorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () => Get.dialog(const RewardQRCode()),
          child: Text('赞助客户端作者（微信赞赏码）', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () => launchURL(Urls.authorSponsor),
          child: Text('赞助客户端作者（爱发电）', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () => launchURL(Urls.xdnmbSponsor),
          child: Text('赞助X岛匿名版官方', style: textStyle),
        ),
      ],
    );
  }
}

class SponsorButton extends StatelessWidget {
  final bool onlyText;

  final bool showLabel;

  final Color? iconColor;

  final EdgeInsetsGeometry? iconPadding;

  final VoidCallback? onTapPrelude;

  const SponsorButton(
      {super.key,
      this.onlyText = true,
      this.showLabel = false,
      this.iconColor,
      this.iconPadding,
      this.onTapPrelude});

  void _onTap() {
    onTapPrelude?.call();

    Get.dialog(const _SponsorDialog());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget icon = Icon(AppIcons.heart, color: iconColor, size: 18.0);

    return onlyText
        ? TextButton(
            onPressed: _onTap,
            child: Text(
              '赞助',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleLarge)
                  ?.merge(
                TextStyle(
                  color: AppTheme.highlightColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        : (showLabel
            ? _Button(
                icon: Padding(
                  padding: const EdgeInsets.only(left: 3.0, top: 3.0),
                  child: icon,
                ),
                label: '赞助',
                onTap: _onTap,
              )
            : IconButton(
                padding: iconPadding,
                onPressed: _onTap,
                tooltip: '赞助',
                icon: icon));
  }
}
