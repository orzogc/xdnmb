import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';

import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reference.dart';
import '../data/models/reply.dart';
import '../data/models/tagged_post.dart';
import '../data/services/tag.dart';
import 'backup.dart';
import 'directory.dart';
import 'extensions.dart';

/// 由于兼容原因，isar数据库名字为`history`
const String _databaseName = 'history';

const String _databaseBackupName = '${_databaseName}_backup';

const List<CollectionSchema<dynamic>> _isarSchemas = [
  BrowseHistorySchema,
  PostDataSchema,
  ReplyDataSchema,
  ReferenceDataSchema,
  TaggedPostSchema,
];

/// [Isar]实例只能同时存在一个
late Isar isar;

String _isarDatabaseFilePath() =>
    join(databaseDirectory, '$_databaseName.isar');

File _isarDatabaseFile() => File(_isarDatabaseFilePath());

String _isarDatabaseBackupFilePath() =>
    join(databaseDirectory, '$_databaseBackupName.isar');

File _isarDatabaseBackupFile() => File(_isarDatabaseBackupFilePath());

File _isarDatabaseBackupLockFile() =>
    File(join(databaseDirectory, '$_databaseBackupName.isar.lock'));

String _isarDatabaseBackupFilePathInDir(String dir) =>
    join(dir, '$_databaseBackupName.isar');

File _isarDatabaseBackupFileInDir(String dir) =>
    File(_isarDatabaseBackupFilePathInDir(dir));

/// 注意iOS设备可能内存不足
Future<Isar> _openIsar(String name, [int? extraSizeMiB]) async {
  final file = File(join(databaseDirectory, '$name.isar'));
  // 默认256MB大小，保留至少100MB左右的空间
  final maxSizeMiB = await file.exists()
      ? ((await file.length() / (1024 * 1024)).floor() + 100)
      : 256;

  return Isar.open(_isarSchemas,
      directory: databaseDirectory,
      name: name,
      maxSizeMiB: max(maxSizeMiB + (extraSizeMiB ?? 0), 256),
      inspector: false);
}

Future<void> initIsar([int? extraSizeMiB]) async =>
    isar = await _openIsar(_databaseName, extraSizeMiB);

class IsarBackupData extends BackupData {
  @override
  String get title => '历史记录、标签及其他数据';

  IsarBackupData();

  @override
  Future<void> backup(String dir) async {
    // 要同时备份标签的hive数据
    await TagBackupRestore.backupHiveTagData(dir);
    progress = 0.5;

    if (!await isar.close()) {
      debugPrint('未能成功关闭isar数据库');
    }

    final isarFile = _isarDatabaseFile();
    await isarFile.copy(_isarDatabaseBackupFilePathInDir(dir));
    progress = 1.0;
  }
}

class IsarRestoreOperator implements CommonRestoreOperator {
  static late Isar backupIsar;

  static int? _backupFileSizeMib;

  static bool _backupIsarIsOpen = false;

  static Future<void> openIsar() async {
    if (!isar.isOpen) {
      await _closeBackupIsar();

      if (_backupFileSizeMib == null) {
        final backupFile = _isarDatabaseBackupFile();
        if (await backupFile.exists()) {
          _backupFileSizeMib =
              (await backupFile.length() / (1024 * 1024)).floor();
        } else {
          throw 'Isar数据库备份文件不存在';
        }
      }

      await initIsar(_backupFileSizeMib);
    }
  }

  static Future<void> _closeIsar() async {
    if (isar.isOpen && !await isar.close()) {
      throw '未能成功关闭Isar数据库';
    }
  }

  static Future<bool> backupIsarExist(String dir) =>
      _isarDatabaseBackupFileInDir(dir).exists();

  static Future<void> openBackupIsar() async {
    if (!_backupIsarIsOpen) {
      await _closeIsar();
      backupIsar = await _openIsar(_databaseBackupName);
      _backupIsarIsOpen = true;
    }
  }

  static Future<void> _closeBackupIsar() async {
    if (_backupIsarIsOpen && !await backupIsar.close()) {
      throw '未能成功关闭Isar备份数据库';
    }
    _backupIsarIsOpen = false;
  }

  const IsarRestoreOperator();

  @override
  Future<void> beforeRestore(String dir) async {
    await _isarDatabaseBackupFile().deleteIfExist();
    await _isarDatabaseBackupLockFile().deleteIfExist();

    await _isarDatabaseBackupFileInDir(dir).copy(_isarDatabaseBackupFilePath());
  }

  @override
  Future<void> afterRestore(String dir) async {
    await _isarDatabaseBackupFile().deleteIfExist();
    await _isarDatabaseBackupLockFile().deleteIfExist();
  }
}
