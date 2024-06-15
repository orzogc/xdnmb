import 'dart:collection';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'directory.dart';
import 'time.dart';

abstract class BackupRestoreBase {
  final ValueNotifier<double> _progressListenable = ValueNotifier(0.0);

  String get title;

  String? get subTitle => null;

  /// 进度为 0.0 到 1.0 的数字
  ValueListenable<double> get progressListenable => _progressListenable;

  /// 返回 0.0 到 1.0 的数字
  double get progress => _progressListenable.value.clamp(0.0, 1.0);

  /// 设置进度
  set progress(double progress) =>
      _progressListenable.value = progress.clamp(0.0, 1.0);

  BackupRestoreBase();
}

abstract class BackupData extends BackupRestoreBase {
  static bool isBackup = false;

  static Future<String> backupData(String saveDir, List<BackupData> list,
      ValueSetter<int> setCompleteNum) async {
    final directory = await getBackupTempDirectory();
    final filename = join(saveDir, 'xdnmb_backup_${filenameFromTime()}.zip');

    try {
      for (var i = 0; i < list.length; i++) {
        setCompleteNum(i);

        debugPrint('正在备份 ${list[i].title}');
        await list[i].backup(directory.path);
      }

      final encoder = ZipFileEncoder();
      encoder.zipDirectory(directory, filename: filename, followLinks: false);
    } catch (e) {
      rethrow;
    } finally {
      isBackup = true;
      await directory.delete(recursive: true);
    }

    setCompleteNum(list.length);
    return filename;
  }

  Future<void> backup(String dir);

  BackupData();
}

/// 子类的构造器必须是 const
abstract class CommonRestoreOperator {
  const CommonRestoreOperator();

  Future<void> beforeRestore(String dir) async {}

  Future<void> afterRestore(String dir) async {}
}

abstract class RestoreData extends BackupRestoreBase {
  static bool isRestored = false;

  static Future<Directory> unzipBackupFile(String backupFile) async {
    final directory = await getBackupTempDirectory();
    await extractFileToDisk(backupFile, directory.path);

    return directory;
  }

  static Future<List<(RestoreData, Object)>> restoreData(String backupDir,
      List<RestoreData> list, ValueSetter<int> setCompleteNum) async {
    final operatorSet = HashSet.of(list
        .map((data) => data.commonOperator)
        .whereType<CommonRestoreOperator>());
    debugPrint('operator 数量：${operatorSet.length}');

    try {
      for (final operator in operatorSet) {
        await operator.beforeRestore(backupDir);
      }

      final errors = <(RestoreData, Object)>[];
      for (var i = 0; i < list.length; i++) {
        try {
          setCompleteNum(i);

          debugPrint('正在恢复 ${list[i].title}');
          await list[i].restore(backupDir);
        } catch (e) {
          debugPrint('恢复 ${list[i].title} 出现错误：$e');
          errors.add((list[i], e));
        }
      }
      setCompleteNum(list.length);

      return errors;
    } catch (e) {
      rethrow;
    } finally {
      isRestored = true;
      for (final operator in operatorSet) {
        await operator.afterRestore(backupDir);
      }
    }
  }

  CommonRestoreOperator? get commonOperator => null;

  Future<bool> canRestore(String dir);

  Future<void> restore(String dir);

  RestoreData();
}
