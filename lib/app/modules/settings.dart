import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/services/version.dart';
import '../routes/routes.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import '../widgets/dialog.dart';

class _Feedback extends StatelessWidget {
  final VoidCallback closeDrawer;

  // ignore: unused_element
  const _Feedback({super.key, required this.closeDrawer});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('反馈问题与建议'),
        onTap: () {
          Get.back();
          closeDrawer();
          AppRoutes.toFeedback();
        },
      );
}

class _AuthorSponsor extends StatelessWidget {
  // ignore: unused_element
  const _AuthorSponsor({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('赞助客户端作者'),
        subtitle: const Text(Urls.authorSponsor),
        onTap: () => launchURL(Urls.authorSponsor),
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

class _AppVersion extends StatelessWidget {
  // ignore: unused_element
  const _AppVersion({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('版本'),
        subtitle: FutureBuilder<String>(
          future: Future(() async {
            final info = await PackageInfo.fromPlatform();
            return info.version;
          }),
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

class SettingsController extends GetxController {
  final VoidCallback closeDrawer;

  SettingsController({required this.closeDrawer});
}

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(Get.arguments as SettingsController);
  }
}

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('设置'),
          ),
          body: ListView(
            children: [
              const ListTile(title: Text('饼干'), onTap: AppRoutes.toUser),
              const ListTile(title: Text('黑名单'), onTap: AppRoutes.toBlacklist),
              const ListTile(
                  title: Text('基本设置'), onTap: AppRoutes.toBasicSettings),
              const ListTile(
                  title: Text('高级设置'), onTap: AppRoutes.toAdvancedSettings),
              _Feedback(closeDrawer: controller.closeDrawer),
              const ListTile(title: Text('客户端作者'), subtitle: Text('Orzogc')),
              const _AuthorSponsor(),
              const _AppSource(),
              const _AppLicense(),
              const _AppVersion(),
            ],
          ),
        ),
      );
}
