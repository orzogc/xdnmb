import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../utils/http_client.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';

class _UseBackupApi extends StatelessWidget {
  // ignore: unused_element
  const _UseBackupApi({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to.client;

    return ListenBuilder(
      listenable: settings.useBackupApiListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('使用X岛备用API'),
        //subtitle: const Text('如果发串返回405错误可以尝试重启应用再发串'),
        value: settings.useBackupApi,
        onChanged: (value) {
          client.useBackupApi(value);
          settings.useBackupApi = value;
        },
      ),
    );
  }
}

class _ConnectionTimeout extends StatelessWidget {
  // ignore: unused_element
  const _ConnectionTimeout({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.connectionTimeoutListenable,
      builder: (context, child) => ListTile(
        title: const Text('建立网络连接的超时时间（秒）'),
        trailing: Text('${settings.connectionTimeout}'),
        onTap: () async {
          final n = await Get.dialog<int>(NumRangeDialog<int>(
              text: '超时秒数', initialValue: settings.connectionTimeout, min: 1));

          if (n != null) {
            settings.connectionTimeout = n;
            XdnmbHttpClient.httpClient.connectionTimeout =
                SettingsService.connectionTimeoutSecond;
          }
        },
      ),
    );
  }
}

class NetworkSettingsView extends StatelessWidget {
  const NetworkSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('网络设置'),
        ),
        body: ListView(
          children: const [_UseBackupApi(), _ConnectionTimeout()],
        ),
      );
}
