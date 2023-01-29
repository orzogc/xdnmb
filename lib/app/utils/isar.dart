import 'package:isar/isar.dart';
import 'package:get/get.dart';

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

Future<void> initIsar() async => isar = await Isar.open(_isarSchemas,
    directory: databasePath,
    name: _databaseName,
    // ios 设备内存不足
    maxSizeMiB: GetPlatform.isIOS ? 1024 : 10240,
    inspector: false);
