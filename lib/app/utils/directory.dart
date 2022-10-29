import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '../data/services/image.dart';

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

/// 获取默认图片保存文件夹
Future<void> getDefaultSaveImagePath() async {
  if (ImageService.savePath == null) {
    if (GetPlatform.isAndroid) {
      // Android上图片默认保存在Pictures/xdnmb文件夹里
      final picturesPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_PICTURES);
      ImageService.savePath = join(picturesPath, directoryName);
    } else if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      // macOS上图片默认保存在应用文档文件夹里，iOS则为临时保存图片
      final directory = await getApplicationDocumentsDirectory();
      ImageService.savePath = directory.path;
    } else if (GetPlatform.isLinux) {
      // Linux上图片默认保存在 ~/Pictures/xdnmb
      final picturesPath = getUserDirectory('PICTURES')?.path ??
          join(Platform.environment['HOME']!, 'Pictures');
      ImageService.savePath = join(picturesPath, directoryName);
    } else if (GetPlatform.isWindows) {
      // Windows上图片默认保存在文档下的xdnmb文件夹里
      final directory = await getApplicationDocumentsDirectory();
      ImageService.savePath = join(directory.path, directoryName);
    } else {
      throw 'Unsupported platform: ${Platform.operatingSystem}';
    }
  }

  // 文件夹不存在则新建文件夹
  final directory = Directory(ImageService.savePath!);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}
