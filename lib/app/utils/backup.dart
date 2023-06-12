import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'directory.dart';
import 'time.dart';
import 'toast.dart';

abstract class BackupRestoreBase {
  final ValueNotifier<double> _progressListenable = ValueNotifier(0.0);

  String get title;

  String? get subTitle => null;

  /// 进度为0.0到1.0的数字
  ValueListenable<double> get progressListenable => _progressListenable;

  /// 返回0.0到1.0的数字
  double get progress => _progressListenable.value.clamp(0.0, 1.0);

  /// 设置进度
  set progress(double progress) =>
      _progressListenable.value = progress.clamp(0.0, 1.0);

  BackupRestoreBase();
}

abstract class BackupData extends BackupRestoreBase {
  static bool _isBackup = false;

  static Future<void> backupData(String saveDir, List<BackupData> list,
      ValueSetter<int> setCompleteNum) async {
    if (!_isBackup && !RestoreData._isRestored) {
      final directory = await getBackupTempDirectory();

      for (var i = 0; i < list.length; i++) {
        setCompleteNum(i);

        await list[i].backup(directory.path);
      }

      final filename = 'xdnmb_backup_${filenameFromTime()}.zip';
      final encoder = ZipFileEncoder();
      encoder.zipDirectory(directory,
          filename: join(saveDir, filename), followLinks: false);
      await directory.delete(recursive: true);
      setCompleteNum(list.length);

      _isBackup = true;
    } else {
      showToast('请重启应用后再备份数据');
    }
  }

  Future<void> backup(String dir);

  BackupData();
}

abstract class RestoreData extends BackupRestoreBase {
  static bool _isRestored = false;

  static Future<Directory> unzipBackupFile(String backupFile) async {
    final directory = await getBackupTempDirectory();
    await extractFileToDisk(backupFile, directory.path);

    return directory;
  }

  static Future<void> restoreData(Directory backupDir, List<RestoreData> list,
      ValueSetter<int> setCompleteNum) async {
    if (!BackupData._isBackup && !_isRestored) {
      for (var i = 0; i < list.length; i++) {
        setCompleteNum(i);

        await list[i].restore(backupDir.path);
      }

      await backupDir.delete(recursive: true);
      setCompleteNum(list.length);

      _isRestored = true;
    } else {
      showToast('请重启应用后再恢复数据');
    }
  }

  Future<bool> canRestore(String dir);

  Future<void> restore(String dir);

  RestoreData();
}
