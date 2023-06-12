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

/// 由于兼容原因，isar数据库名字为`history`
const String _databaseName = 'history';

const List<CollectionSchema<dynamic>> _isarSchemas = [
  BrowseHistorySchema,
  PostDataSchema,
  ReplyDataSchema,
  ReferenceDataSchema,
  TaggedPostSchema,
];

/// [Isar]实例只能同时存在一个
late final Isar isar;

File _isarDatabaseFile() =>
    File(join(databaseDirectory, '$_databaseName.isar'));

String _isarDatabaseBackupFilePath(String dir) =>
    join(dir, '${_databaseName}_backup.isar');

/* File _isarDatabaseBackupFile(String dir) =>
    File(_isarDatabaseBackupFilePath(dir)); */

/// 注意iOS设备可能内存不足
Future<void> initIsar() async {
  final databaseFile = _isarDatabaseFile();
  // 默认256MB大小，保留至少100MB左右的空间
  final maxSizeMiB = await databaseFile.exists()
      ? ((await databaseFile.length() / (1024 * 1024)).floor() + 100)
      : 256;

  isar = await Isar.open(_isarSchemas,
      directory: databaseDirectory,
      name: _databaseName,
      maxSizeMiB: max(maxSizeMiB, 256),
      inspector: false);
}

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
    await isarFile.copy(_isarDatabaseBackupFilePath(dir));
    progress = 1.0;
  }
}
