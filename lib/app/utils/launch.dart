import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchURL(String url) async => launchUri(Uri.parse(url));

Future<void> launchUri(Uri uri) async {
  try {
    if (!await launchUrl(uri)) {
      debugPrint('打开链接 $uri 失败');
    }
  } catch (e) {
    debugPrint('打开链接 $uri 失败：$e');
  }
}
