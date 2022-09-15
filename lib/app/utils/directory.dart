import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart';

const String directoryName = 'xdnmb';

Future<String> hivePath() async {
  late final String path;

  if (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS) {
    final directory = await getApplicationSupportDirectory();
    path = directory.path;
  } else if (GetPlatform.isLinux) {
    path = join(dataHome.path, directoryName);
  } else if (GetPlatform.isWindows) {
    final directory = await getApplicationSupportDirectory();
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

Future<String> picturesPath() async {
  late final String path;

  if (GetPlatform.isAndroid) {
    final picturesPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_PICTURES);
    path = join(picturesPath, directoryName);
  } else if (GetPlatform.isIOS || GetPlatform.isMacOS) {
    final directory = await getApplicationDocumentsDirectory();
    path = directory.path;
  } else if (GetPlatform.isLinux) {
    final picturesPath = getUserDirectory('PICTURES')?.path ??
        join(Platform.environment['HOME']!, 'Pictures');
    path = join(picturesPath, directoryName);
  } else if (GetPlatform.isWindows) {
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
