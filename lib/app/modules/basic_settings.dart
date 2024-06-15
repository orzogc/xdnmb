import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';
import '../widgets/listenable.dart';

class _RestoreTabs extends StatelessWidget {
  // ignore: unused_element
  const _RestoreTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
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

    return ListenBuilder(
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
            constraints: const BoxConstraints(maxWidth: 150.0),
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

    return ListenBuilder(
      listenable: settings.showImageListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('显示图片'),
        value: settings.showImage,
        onChanged: (value) => settings.showImage = value,
      ),
    );
  }
}

class _ShowLargeImageInPost extends StatelessWidget {
  // ignore: unused_element
  const _ShowLargeImageInPost({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.showLargeImageInPostListenable,
      builder: (context, child) => SwitchListTile(
          title: const Text("点击略缩图直接在串内展示大图"),
          value: settings.showLargeImageInPost,
          onChanged: (value) => settings.showLargeImageInPost = value),
    );
  }
}

class _Watermark extends StatelessWidget {
  // ignore: unused_element
  const _Watermark({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
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
      trailing: ListenBuilder(
        listenable: settings.jumpToLastBrowseSettingListenable,
        builder: (context, child) => DropdownButton<int>(
          value: settings.jumpToLastBrowseSetting,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: (value) {
            if (value != null) {
              settings.jumpToLastBrowseSetting = value;
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
        ),
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    // autocorrect: false
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
    // autocorrect: true
  }
}

class _FeedId extends StatelessWidget {
  // ignore: unused_element
  const _FeedId({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: Listenable.merge(
          [UserService.to.browseCookieListenable, settings.feedIdListenable]),
      builder: (context, child) {
        final textStyle = TextStyle(
            color: settings.useHtmlFeed ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          // autocorrect: false
          title: Text('订阅ID', style: textStyle),
          // autocorrect: true
          subtitle: Text(settings.feedId, style: textStyle),
          onTap: !settings.useHtmlFeed ? () => Get.dialog(_EditFeedId()) : null,
        );
      },
    );
  }
}

class _UseHtmlFeed extends StatelessWidget {
  // ignore: unused_element
  const _UseHtmlFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: Listenable.merge(
          [user.browseCookieListenable, settings.useHtmlFeedListenable]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '使用跟浏览饼干绑定的网页版订阅',
          style: TextStyle(
            color: !user.hasBrowseCookie ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        subtitle: const Text('使用网页版订阅会导致无法显示最后回复时间'),
        value: settings.useHtmlFeed,
        onChanged: user.hasBrowseCookie
            ? (value) => settings.useHtmlFeed = value
            : null,
      ),
    );
  }
}

class BasicSettingsView extends StatelessWidget {
  const BasicSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('基本设置')),
        body: ListView(
          children: const [
            _RestoreTabs(),
            _InitialForum(),
            _ShowImage(),
            _ShowLargeImageInPost(),
            _Watermark(),
            _AutoJump(),
            _AfterPostRefresh(),
            _DismissibleTab(),
            _SelectCookieBeforePost(),
            _ForbidDuplicatedPosts(),
            _FeedId(),
            _UseHtmlFeed(),
          ],
        ),
      );
}
