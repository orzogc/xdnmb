import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/models/controller.dart';
import '../data/models/cookie.dart';
import '../data/models/emoticon.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import '../data/models/tag.dart';
import 'directory.dart';

/// 初始化 Hive 数据库
Future<void> initHive() async {
  Hive.init(databaseDirectory);

  Hive.registerAdapter<ForumData>(ForumDataAdapter());
  Hive.registerAdapter<CookieData>(CookieDataAdapter());
  Hive.registerAdapter<PostDraftData>(PostDraftDataAdapter());
  Hive.registerAdapter<EmoticonData>(EmoticonDataAdapter());
  Hive.registerAdapter<BlockForumData>(BlockForumDataAdapter());
  Hive.registerAdapter<DateTimeRange>(DateTimeRangeAdapter());
  Hive.registerAdapter<PostBaseData>(PostBaseDataAdapter());
  Hive.registerAdapter<PostListType>(PostListTypeAdapter());
  Hive.registerAdapter<PostListControllerData>(PostListControllerDataAdapter());
  Hive.registerAdapter<Search>(SearchAdapter());
  Hive.registerAdapter<TagData>(TagDataAdapter());
}
