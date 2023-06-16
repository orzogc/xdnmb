import 'dart:collection';
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

  /// 备份成功返回`true`，否则返回`false`
  static Future<(bool, String?)> backupData(String saveDir,
      List<BackupData> list, ValueSetter<int> setCompleteNum) async {
    if (!_isBackup && !RestoreData._isRestored) {
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
        await directory.delete(recursive: true);
        _isBackup = true;
      }

      setCompleteNum(list.length);
      return (true, filename);
    } else {
      showToast('请重启应用后再备份数据');

      return (false, null);
    }
  }

  Future<void> backup(String dir);

  BackupData();
}

/// 子类的构造器必须是const
abstract class CommonRestoreOperator {
  const CommonRestoreOperator();

  Future<void> beforeRestore(String dir) async {}

  Future<void> afterRestore(String dir) async {}
}

abstract class RestoreData extends BackupRestoreBase {
  static bool _isRestored = false;

  static Future<Directory> unzipBackupFile(String backupFile) async {
    final directory = await getBackupTempDirectory();
    await extractFileToDisk(backupFile, directory.path);

    return directory;
  }

  /// 恢复成功返回`true`，否则返回`false`
  static Future<bool> restoreData(Directory backupDir, List<RestoreData> list,
      ValueSetter<int> setCompleteNum) async {
    if (!BackupData._isBackup && !_isRestored) {
      final operatorSet = HashSet.of(list
          .map((data) => data.commonOperator)
          .whereType<CommonRestoreOperator>());
      debugPrint('operator数量：${operatorSet.length}');
      for (final operator in operatorSet) {
        await operator.beforeRestore(backupDir.path);
      }

      try {
        final errors = <String>[];
        for (var i = 0; i < list.length; i++) {
          setCompleteNum(i);

          debugPrint('正在恢复 ${list[i].title}');
          try {
            await list[i].restore(backupDir.path);
          } catch (e) {
            debugPrint('恢复 ${list[i].title} 出现错误：$e');
            errors.add(list[i].title);
          }
        }

        if (errors.isNotEmpty) {
          throw '恢复和合并 ${errors.join('、')} 的备份数据失败，其余备份数据恢复成功';
        }
      } catch (e) {
        rethrow;
      } finally {
        for (final operator in operatorSet) {
          await operator.afterRestore(backupDir.path);
        }

        await backupDir.delete(recursive: true);
        _isRestored = true;
      }

      setCompleteNum(list.length);
      return true;
    } else {
      showToast('请重启应用后再恢复数据');
      return false;
    }
  }

  CommonRestoreOperator? get commonOperator => null;

  Future<bool> canRestore(String dir);

  Future<void> restore(String dir);

  RestoreData();
}
