import 'package:hive/hive.dart';

import '../data/models/cookie.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import 'directory.dart';

// TODO: Compaction
Future<void> initHive() async {
  Hive.init(await hivePath());

  Hive.registerAdapter(CookieDataAdapter());
  Hive.registerAdapter(ForumDataAdapter());
  Hive.registerAdapter(PostDraftDataAdapter());
}
