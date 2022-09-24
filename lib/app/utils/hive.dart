import 'package:hive/hive.dart';

import '../data/models/cookie.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import 'directory.dart';

Future<void> initHive() async {
  Hive.init(databasePath);

  Hive.registerAdapter(CookieDataAdapter());
  Hive.registerAdapter(ForumDataAdapter());
  Hive.registerAdapter(PostDraftDataAdapter());
}
