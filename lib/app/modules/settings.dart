import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/services/settings.dart';
import '../data/services/version.dart';
import '../routes/routes.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';

class _DarkMode extends StatelessWidget {
  // ignore: unused_element
  const _DarkMode({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.isDarkModeListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('黑夜模式'),
        subtitle: settings.isDarkMode ? const Text('光来！') : const Text('暗来！'),
        value: settings.isDarkMode,
        onChanged: (value) => settings.isDarkMode = value,
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  // ignore: unused_element
  const _Feedback({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('反馈客户端问题与建议'),
        onTap: () {
          Get.back();
          AppRoutes.toFeedback();
        },
      );
}

class _AuthorQRCodeSponsor extends StatelessWidget {
  // ignore: unused_element
  const _AuthorQRCodeSponsor({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('赞助客户端作者（微信赞赏码）'),
        onTap: () => Get.dialog(const RewardQRCode()),
      );
}

class _AuthorUrlSponsor extends StatelessWidget {
  // ignore: unused_element
  const _AuthorUrlSponsor({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('赞助客户端作者（爱发电）'),
        subtitle: const Text(Urls.authorSponsor),
        onTap: () => launchURL(Urls.authorSponsor),
      );
}

class _XdnmbUrlSponsor extends StatelessWidget {
  // ignore: unused_element
  const _XdnmbUrlSponsor({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('赞助X岛匿名版官方'),
        subtitle: const Text(Urls.xdnmbSponsor),
        onTap: () => launchURL(Urls.xdnmbSponsor),
      );
}

class _AppSource extends StatelessWidget {
  // ignore: unused_element
  const _AppSource({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('源码'),
        subtitle: const Text(Urls.appSource),
        onTap: () => launchURL(Urls.appSource),
      );
}

class _AppLicense extends StatelessWidget {
  // ignore: unused_element
  const _AppLicense({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('开源许可证'),
        subtitle: const Text('GNU Affero General Public License Version 3'),
        onTap: () async => Get.dialog(
          ConfirmCancelDialog(
            content: await DefaultAssetBundle.of(context).loadString('LICENSE'),
            onConfirm: () => Get.back(),
          ),
        ),
      );
}

class _AppChangelog extends StatelessWidget {
  // ignore: unused_element
  const _AppChangelog({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('更新记录'),
        onTap: () async => Get.dialog(
          ConfirmCancelDialog(
            content:
                await DefaultAssetBundle.of(context).loadString('CHANGELOG.md'),
            onConfirm: () => Get.back(),
          ),
        ),
      );
}

class _AppVersion extends StatelessWidget {
  final Future<String> _getVersion =
      PackageInfo.fromPlatform().then((info) => info.version);

  // ignore: unused_element
  _AppVersion({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('版本'),
        subtitle: FutureBuilder<String>(
          future: _getVersion,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Text('${snapshot.data}');
            }

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasError) {
              showToast('获取版本号出现错误：${snapshot.error}');
            }

            return const SizedBox.shrink();
          },
        ),
        onTap: () => CheckAppVersionService.to.checkUpdate(),
      );
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: ListView(
          children: [
            const ListTile(title: Text('饼干'), onTap: AppRoutes.toUser),
            const ListTile(title: Text('黑名单'), onTap: AppRoutes.toBlacklist),
            const ListTile(
                title: Text('基本设置'), onTap: AppRoutes.toBasicSettings),
            const ListTile(title: Text('界面设置'), onTap: AppRoutes.toUISettings),
            const ListTile(
                title: Text('高级设置'), onTap: AppRoutes.toAdvancedSettings),
            const _DarkMode(),
            const ListTile(title: Text('应用数据备份与恢复'), onTap: AppRoutes.toBackup),
            const _Feedback(),
            const ListTile(title: Text('客户端作者'), subtitle: Text('Orzogc')),
            const _AuthorQRCodeSponsor(),
            const _AuthorUrlSponsor(),
            const _XdnmbUrlSponsor(),
            const _AppSource(),
            const _AppLicense(),
            const _AppChangelog(),
            _AppVersion(),
          ],
        ),
      );
}
