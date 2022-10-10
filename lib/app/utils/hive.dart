import 'package:hive/hive.dart';

import '../data/models/cookie.dart';
import '../data/models/emoticon.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import 'directory.dart';

Future<void> initHive() async {
  Hive.init(databasePath);

  Hive.registerAdapter<ForumData>(ForumDataAdapter());
  Hive.registerAdapter<CookieData>(CookieDataAdapter());
  Hive.registerAdapter<PostDraftData>(PostDraftDataAdapter());
  Hive.registerAdapter<EmoticonData>(EmoticonDataAdapter());
  Hive.registerAdapter<BlockForumData>(BlockForumDataAdapter());
}
