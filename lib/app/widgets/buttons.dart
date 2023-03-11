import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/icons.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'dialog.dart';
import 'reference.dart';

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

class _SearchDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: unused_element
  _SearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    String? content;

    return InputDialog(
      title: const Text('搜索'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          autofocus: true,
          onSaved: (newValue) => content = newValue,
          validator: (value) =>
              (value == null || value.isEmpty) ? '请输入搜索内容' : null,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final postId = Regex.getPostId(content!);
              if (postId == null) {
                showToast('请输入串号');
                return;
              }

              Get.back<bool>(result: true);
              postListDialog(Center(child: ReferenceCard(postId: postId)));
            }
          },
          child: const Text('查询串号'),
        ),
        const ElevatedButton(
          onPressed: null,
          child: Text('搜索坏了', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class SearchButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final VoidCallback? onTapPrelude;

  final VoidCallback? afterSearch;

  const SearchButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.onTapPrelude,
      this.afterSearch});

  Future<void> _onTap() async {
    onTapPrelude?.call();

    final result = await Get.dialog<bool>(_SearchDialog());
    if ((result ?? false) && afterSearch != null) {
      afterSearch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.search, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '搜索', onTap: _onTap)
        : IconButton(onPressed: _onTap, tooltip: '搜索', icon: icon);
  }
}

class SettingsButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final VoidCallback? onTapPrelude;

  const SettingsButton(
      {super.key, this.showLabel = false, this.iconColor, this.onTapPrelude});

  void _onTap() {
    onTapPrelude?.call();
    AppRoutes.toSettings();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.settings, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '设置', onTap: _onTap)
        : IconButton(onPressed: _onTap, tooltip: '设置', icon: icon);
  }
}

class HistoryButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final VoidCallback? onTapPrelude;

  final VoidCallback? onTapEnd;

  const HistoryButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.onTapPrelude,
      this.onTapEnd});

  void _onTap() {
    onTapPrelude?.call();

    if (!PostListController.get().isHistory) {
      AppRoutes.toHistory();
    }

    onTapEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.history, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '历史', onTap: _onTap)
        : IconButton(onPressed: _onTap, tooltip: '历史', icon: icon);
  }
}

class FeedButton extends StatelessWidget {
  final bool showLabel;

  final Color? iconColor;

  final VoidCallback? onTapPrelude;

  final VoidCallback? onTapEnd;

  const FeedButton(
      {super.key,
      this.showLabel = false,
      this.iconColor,
      this.onTapPrelude,
      this.onTapEnd});

  void _onTap() {
    onTapPrelude?.call();

    if (!PostListController.get().isFeed) {
      AppRoutes.toFeed();
    }

    onTapEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.rss_feed, color: iconColor);

    return showLabel
        ? _Button(icon: icon, label: '订阅', onTap: _onTap)
        : IconButton(onPressed: _onTap, tooltip: '订阅/标签', icon: icon);
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

  final VoidCallback? onTapPrelude;

  const SponsorButton(
      {super.key,
      this.onlyText = true,
      this.showLabel = false,
      this.iconColor,
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
            : IconButton(onPressed: _onTap, tooltip: '赞助', icon: icon));
  }
}
