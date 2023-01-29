import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:path/path.dart';

import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reference.dart';
import '../data/models/reply.dart';
import 'directory.dart';

/// 由于兼容原因，isar数据库名字为`history`
const String _databaseName = 'history';

final List<CollectionSchema<dynamic>> _isarSchemas = [
  BrowseHistorySchema,
  PostDataSchema,
  ReplyDataSchema,
  ReferenceDataSchema,
];

/// [Isar]实例只能同时存在一个
late final Isar isar;

/// 注意iOS设备可能内存不足
Future<void> initIsar() async {
  final databaseFile = File(join(databasePath, '$_databaseName.isar'));
  // 至少保留200MB左右的空间
  final maxSizeGiB = await databaseFile.exists()
      ? ((await databaseFile.length() / (1024 * 1024 * 1024) + 0.2).floor() + 1)
      : 1;

  isar = await Isar.open(_isarSchemas,
      directory: databasePath,
      name: _databaseName,
      maxSizeMiB: max(maxSizeGiB, 1) * 1024,
      inspector: false);
}
