import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'app/data/services/services.dart';
import 'app/routes/pages.dart';
import 'app/routes/routes.dart';
import 'app/utils/directory.dart';
import 'app/utils/hive.dart';
import 'app/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = CustomHttpOverrides();

  await getDatabasePath();

  // TODO: 错误页面和404页面
  try {
    await initHive();
  } catch (e) {
    debugPrint('初始化Hive失败：$e');
    return;
  }

  runApp(const XdnmbApp());

  await Hive.close();
}

class XdnmbApp extends StatelessWidget {
  const XdnmbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'X岛',
      initialBinding: servicesBindings(),
      getPages: getPages,
      initialRoute: AppRoutes.timelineUrl(1),
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      builder: EasyLoading.init(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
}

/// 过滤掉可能出现的证书错误
///
/// 测试用，发布正式版本需要去掉
class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }

  /* @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    environment = environment ?? {};
    environment['http_proxy'] = '127.0.0.1:8118';
    environment['https_proxy'] = '127.0.0.1:8118';

    return super.findProxyFromEnvironment(url, environment);
  } */
}
