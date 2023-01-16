import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';
import '../widgets/listenable.dart';
import '../widgets/safe_area.dart';

class _RestoreTabs extends StatelessWidget {
  // ignore: unused_element
  const _RestoreTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.isRestoreTabsListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('应用启动后恢复标签页'),
        value: settings.isRestoreTabs,
        onChanged: (value) => settings.isRestoreTabs = value,
      ),
    );
  }
}

class _InitialForum extends StatelessWidget {
  // ignore: unused_element
  const _InitialForum({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.initialForumListenable,
      builder: (context, child) => ListTile(
        title: Text(
          '应用启动后显示的版块',
          style: TextStyle(
            color:
                settings.isRestoreTabs ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        trailing: TextButton(
          onPressed: settings.isRestoreTabs
              ? null
              : () => Get.dialog(
                    SelectForum(
                      onSelect: (forum) {
                        settings.initialForum = forum.copy();
                        Get.back();
                      },
                    ),
                  ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: ForumName(
              forumId: settings.initialForum.id,
              isTimeline: settings.initialForum.isTimeline,
              textStyle: TextStyle(
                  color: settings.isRestoreTabs
                      ? Colors.grey
                      : AppTheme.highlightColor),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowImage extends StatelessWidget {
  // ignore: unused_element
  const _ShowImage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showImageListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('显示图片'),
        value: settings.showImage,
        onChanged: (value) => settings.showImage = value,
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  // ignore: unused_element
  const _Watermark({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.isWatermarkListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('发送图片默认附带水印'),
        value: settings.isWatermark,
        onChanged: (value) => settings.isWatermark = value,
      ),
    );
  }
}

class _AutoJump extends StatelessWidget {
  // ignore: unused_element
  const _AutoJump({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      title: const Text('打开串时自动跳转到最近浏览的页数和位置'),
      trailing: ListenableBuilder(
        listenable: Listenable.merge([
          settings.isJumpToLastBrowsePageListenable,
          settings.isJumpToLastBrowsePositionListenable,
        ]),
        builder: (context, child) {
          final int n = settings.isJumpToLastBrowsePage
              ? (settings.isJumpToLastBrowsePosition ? 0 : 1)
              : 2;

          return DropdownButton<int>(
            value: n,
            alignment: Alignment.centerRight,
            underline: const SizedBox.shrink(),
            icon: const SizedBox.shrink(),
            style: textStyle,
            onChanged: (value) {
              if (value != null) {
                value = value.clamp(0, 2);
                switch (value) {
                  case 0:
                    settings.isJumpToLastBrowsePage = true;
                    settings.isJumpToLastBrowsePosition = true;
                    break;
                  case 1:
                    settings.isJumpToLastBrowsePage = true;
                    settings.isJumpToLastBrowsePosition = false;
                    break;
                  case 2:
                    settings.isJumpToLastBrowsePage = false;
                    settings.isJumpToLastBrowsePosition = false;
                    break;
                }
              }
            },
            items: const [
              DropdownMenuItem<int>(
                value: 0,
                alignment: Alignment.centerRight,
                child: Text('跳转位置'),
              ),
              DropdownMenuItem<int>(
                value: 1,
                alignment: Alignment.centerRight,
                child: Text('只跳转页数'),
              ),
              DropdownMenuItem<int>(
                value: 2,
                alignment: Alignment.centerRight,
                child: Text('不跳转'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AfterPostRefresh extends StatelessWidget {
  // ignore: unused_element
  const _AfterPostRefresh({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.isAfterPostRefreshListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('发表新串后自动刷新页面'),
        value: settings.isAfterPostRefresh,
        onChanged: (value) => settings.isAfterPostRefresh = value,
      ),
    );
  }
}

class _DismissibleTab extends StatelessWidget {
  // ignore: unused_element
  const _DismissibleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.dismissibleTabListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('在标签页列表中滑动标签可以关闭标签页'),
        value: settings.dismissibleTab,
        onChanged: (value) => settings.dismissibleTab = value,
      ),
    );
  }
}

class _SelectCookieBeforePost extends StatelessWidget {
  // ignore: unused_element
  const _SelectCookieBeforePost({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.selectCookieBeforePostListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('发串时选择饼干'),
        value: settings.selectCookieBeforePost,
        onChanged: (value) => settings.selectCookieBeforePost = value,
      ),
    );
  }
}

class _ForbidDuplicatedPosts extends StatelessWidget {
  // ignore: unused_element
  const _ForbidDuplicatedPosts({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.forbidDuplicatedPostsListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('时间线和版块过滤重复的串'),
        value: settings.forbidDuplicatedPosts,
        onChanged: (value) => settings.forbidDuplicatedPosts = value,
      ),
    );
  }
}

class _EditFeedId extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: unused_element
  _EditFeedId({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final feedId = settings.feedId.obs;
    String? id;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: Obx(
          () => TextFormField(
            key: ValueKey<String>(feedId.value),
            decoration: const InputDecoration(labelText: '订阅ID'),
            autofocus: true,
            initialValue: feedId.value,
            onSaved: (newValue) => id = newValue,
            validator: (value) => value == null ? '请输入订阅ID' : null,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => feedId.value = const Uuid().v4(),
          child: const Text('生成UUID'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              settings.feedId = id!;
              Get.back();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _FeedId extends StatelessWidget {
  // ignore: unused_element
  const _FeedId({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.feedIdListenable,
      builder: (context, child) => ListTile(
        title: const Text('订阅ID'),
        subtitle: Text(settings.feedId),
        trailing: child,
        onTap: () => Get.dialog(_EditFeedId()),
      ),
      child: TextButton(
        onPressed: () => Get.dialog(_EditFeedId()),
        child: const Text('编辑'),
      ),
    );
  }
}

class BasicSettingsView extends StatelessWidget {
  const BasicSettingsView({super.key});

  @override
  Widget build(BuildContext context) => ColoredSafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('基本设置')),
          body: ListView(
            children: const [
              _RestoreTabs(),
              _InitialForum(),
              _ShowImage(),
              _Watermark(),
              _AutoJump(),
              _AfterPostRefresh(),
              _DismissibleTab(),
              _SelectCookieBeforePost(),
              _ForbidDuplicatedPosts(),
              _FeedId(),
            ],
          ),
        ),
      );
}
