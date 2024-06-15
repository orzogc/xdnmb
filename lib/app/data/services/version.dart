import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_info2/system_info2.dart';
import 'package:version/version.dart';

import '../../utils/http_client.dart';
import '../../utils/toast.dart';
import '../../utils/url.dart';
import '../../widgets/dialog.dart';

class CheckAppVersionService extends GetxService {
  static final CheckAppVersionService to = Get.find<CheckAppVersionService>();

  static const Duration _checkUpdatePeriod = Duration(seconds: 10);

  String? _latestVersion;

  String? _updateMessage;

  DateTime? _lastCheckUpdate;

  bool isReady = false;

  Future<void> _getLatestVersion() async {
    if (!GetPlatform.isIOS) {
      try {
        final response =
            await XdnmbHttpClient().get(Uri.parse(Urls.appLatestVersion));
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        _latestVersion = data['version'];
        debugPrint('成功获取应用最新版本：$_latestVersion');
      } catch (e) {
        showToast('获取应用最新版本出错：$e');
      }
    }
  }

  void _showUpdateDialog(String url) => Get.dialog(NewVersionDialog(
      url: url, latestVersion: _latestVersion, updateMessage: _updateMessage));

  Future<bool> _hasNewVersion() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    return _latestVersion != null &&
        Version.parse(_latestVersion!) > Version.parse(currentVersion);
  }

  Future<void> checkAppVersion() async {
    if (!GetPlatform.isIOS) {
      while (!isReady) {
        debugPrint('正在等待获取应用最新版本');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      try {
        if (await _hasNewVersion()) {
          debugPrint('开始获取版本更新信息');
          final response =
              await XdnmbHttpClient().get(Uri.parse(Urls.appUpdateMessage));
          final List<dynamic> list =
              json.decode(utf8.decode(response.bodyBytes));
          for (final Map<String, dynamic> data in list) {
            if (data['version'] == _latestVersion) {
              _updateMessage = data['message'];
            }
          }

          if (GetPlatform.isLinux ||
              GetPlatform.isMacOS ||
              GetPlatform.isWindows) {
            _showUpdateDialog(Urls.appLatestRelease);
          } else if (GetPlatform.isAndroid) {
            switch (SysInfo.kernelArchitecture) {
              case ProcessorArchitecture.x86_64:
                _showUpdateDialog(Urls.appX8664Apk);
                break;
              case ProcessorArchitecture.arm:
                _showUpdateDialog(Urls.appArmeabiv7aApk);
                break;
              case ProcessorArchitecture.arm64:
                _showUpdateDialog(Urls.appArm64Apk);
                break;
              default:
                debugPrint(
                    '可能不支持下载更新的 Android CPU 架构：${SysInfo.kernelArchitecture}');
                _showUpdateDialog(Urls.appFullApk);
            }
          } else {
            debugPrint('不支持下载更新的平台：${Platform.operatingSystem}');
          }
        }
      } catch (e) {
        showToast('检查应用新版本出错：$e');
      }
    }
  }

  Future<void> checkUpdate() async {
    if (!GetPlatform.isIOS &&
        (_lastCheckUpdate == null ||
            DateTime.now().difference(_lastCheckUpdate!) >=
                _checkUpdatePeriod)) {
      await _getLatestVersion();
      if (await _hasNewVersion()) {
        await checkAppVersion();
      } else {
        showToast('没有新版本');
      }

      _lastCheckUpdate = DateTime.now();
    }
  }

  @override
  void onReady() async {
    super.onReady();

    await _getLatestVersion();

    debugPrint('获取应用最新版本完成');
    isReady = true;
  }

  @override
  void onClose() {
    isReady = false;

    super.onClose();
  }
}
