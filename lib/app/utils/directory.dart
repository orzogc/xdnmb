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
late final String databaseDirectory;

/// 获取数据库文件夹路径，保存在[databaseDirectory]
Future<void> getDatabasePath() async {
  if (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS) {
    // Android、iOS和macOS上数据库保存在应用支持文件夹里
    final directory = await getApplicationSupportDirectory();
    databaseDirectory = directory.path;
  } else if (GetPlatform.isLinux) {
    // Linux上数据库保存在 ~/.local/share/xdnmb
    databaseDirectory = join(dataHome.path, directoryName);
  } else if (GetPlatform.isWindows) {
    // Windows上数据库保存在Roaming文件夹
    final directory = await getApplicationSupportDirectory();
    databaseDirectory = join(directory.path, directoryName);
  } else {
    throw 'Unsupported platform: ${Platform.operatingSystem}';
  }

  final directory = Directory(databaseDirectory);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

/// 图片文件夹名字
const String pictureDirectoryName = 'pictures';

/// 获取默认图片保存文件夹
Future<void> getDefaultSaveImagePath() async {
  if (ImageService.savePath == null &&
      !(GetPlatform.isIOS || GetPlatform.isMacOS)) {
    if (GetPlatform.isAndroid) {
      // Android上图片默认保存在Pictures/xdnmb文件夹里
      final picturesPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_PICTURES);
      ImageService.savePath = join(picturesPath, directoryName);
    } else if (GetPlatform.isLinux) {
      // Linux上图片默认保存在 ~/Pictures/xdnmb
      final picturesPath = getUserDirectory('PICTURES')?.path ??
          join(Platform.environment['HOME']!, 'Pictures');
      ImageService.savePath = join(picturesPath, directoryName);
    } else if (GetPlatform.isWindows) {
      // Windows上图片默认保存在文档下的xdnmb文件夹里
      final directory = await getApplicationDocumentsDirectory();
      ImageService.savePath = join(directory.path, pictureDirectoryName);
    } else {
      throw 'Unsupported platform: ${Platform.operatingSystem}';
    }
  } else if (GetPlatform.isIOS || GetPlatform.isMacOS) {
    // iOS 系统在一些情况下（如更新应用后），目录会发生改变，所以不能缓存
    // macOS上图片默认保存在应用文档文件夹里的pictures文件夹，iOS则为临时保存图片
    final directory = GetPlatform.isIOS
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    ImageService.savePath = GetPlatform.isIOS
        ? directory.path
        : join(directory.path, pictureDirectoryName);
  }

  // 文件夹不存在则新建文件夹
  final directory = Directory(ImageService.savePath!);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

const String backupDirectoryPrefix = 'xdnmbBackup';

Future<Directory> getBackupTempDirectory() async {
  final directory = await getTemporaryDirectory();
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return directory.createTemp(backupDirectoryPrefix);
}
