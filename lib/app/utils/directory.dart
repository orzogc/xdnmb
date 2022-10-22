import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart';

/// 文件夹名字
const String directoryName = 'xdnmb';

/// 数据库文件夹路径
late final String databasePath;

/// 获取数据库文件夹路径，保存在[databasePath]
Future<void> getDatabasePath() async {
  if (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS) {
    // Android、iOS和macOS上数据库保存在应用支持文件夹里
    final directory = await getApplicationSupportDirectory();
    databasePath = directory.path;
  } else if (GetPlatform.isLinux) {
    // Linux上数据库保存在 ~/.local/share/xdnmb
    databasePath = join(dataHome.path, directoryName);
  } else if (GetPlatform.isWindows) {
    // Windows上数据库保存在Roaming文件夹
    final directory = await getApplicationSupportDirectory();
    databasePath = join(directory.path, directoryName);
  } else {
    throw 'Unsupported platform: ${Platform.operatingSystem}';
  }

  final directory = Directory(databasePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

/// 返回图片保存文件夹
Future<String> getPicturesPath() async {
  late final String path;

  if (GetPlatform.isAndroid) {
    // Android上图片保存在Pictures文件夹里
    final picturesPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_PICTURES);
    path = join(picturesPath, directoryName);
  } else if (GetPlatform.isIOS || GetPlatform.isMacOS) {
    // iOS和macOS上图片保存在应用文档文件夹里
    final directory = await getApplicationDocumentsDirectory();
    path = directory.path;
  } else if (GetPlatform.isLinux) {
    // Linux上图片保存在 ~/Pictures/xdnmb
    final picturesPath = getUserDirectory('PICTURES')?.path ??
        join(Platform.environment['HOME']!, 'Pictures');
    path = join(picturesPath, directoryName);
  } else if (GetPlatform.isWindows) {
    // Windows上图片保存在文档下的xdnmb文件夹里
    final directory = await getApplicationDocumentsDirectory();
    path = join(directory.path, directoryName);
  } else {
    throw 'Unsupported platform: ${Platform.operatingSystem}';
  }

  final directory = Directory(path);
  if (await directory.exists()) {
    return path;
  } else {
    final created = await directory.create(recursive: true);

    return created.path;
  }
}
