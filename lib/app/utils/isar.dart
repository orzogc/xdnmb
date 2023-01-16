import 'package:isar/isar.dart';

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

/// [Isar]实例只能存在一个
late final Isar isar;

Future<void> initIsar() async => isar = await Isar.open(_isarSchemas,
    directory: databasePath, name: _databaseName, inspector: false);
