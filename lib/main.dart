import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'app/data/services/persistent.dart';
import 'app/data/services/services.dart';
import 'app/data/services/settings.dart';
import 'app/modules/post_list.dart';
import 'app/routes/pages.dart';
import 'app/routes/routes.dart';
import 'app/utils/directory.dart';
import 'app/utils/hive.dart';
import 'app/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _addCert();

  await getDatabasePath();
  try {
    await initHive();
  } catch (e) {
    debugPrint('初始化Hive失败：$e');
    return;
  }
  await SettingsService.getSettings();
  await PersistentDataService.getData();

  runApp(const _XdnmbApp());

  await Hive.close();
}

/// xdnmb应用
class _XdnmbApp extends StatelessWidget {
  // ignore: unused_element
  const _XdnmbApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: '霞岛',
        initialBinding: servicesBindings(),
        getPages: !SettingsService.isBackdropUI ? getPages : null,
        initialRoute: AppRoutes.home,
        onGenerateInitialRoutes: SettingsService.isBackdropUI
            ? (initialRoute) =>
                [SwipeablePageRoute(builder: (context) => const PostListView())]
            : null,
        onGenerateRoute:
            SettingsService.isBackdropUI ? backdropOnGenerateRoute : null,
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        builder: EasyLoading.init(),
        // Flutter官方的翻译
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 支持的locale
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
          Locale('en', ''),
          Locale('en', 'US'),
        ],
        debugShowCheckedModeBanner: false,
      );
}

/// 添加 Let’s Encrypt 的证书
///
/// Let’s Encrypt 的旧证书过期导致部分旧手机无法访问X岛链接
Future<void> _addCert() async {
  // 可能只有Android旧手机有此问题？
  if (GetPlatform.isAndroid) {
    final data =
        await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asInt8List());
  }
}
