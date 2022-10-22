import 'package:get/get.dart';

import 'blacklist.dart';
import 'draft.dart';
import 'emoticon.dart';
import 'forum.dart';
import 'history.dart';
import 'image.dart';
import 'persistent.dart';
import 'settings.dart';
import 'time.dart';
import 'user.dart';
import 'xdnmb_client.dart';

/// 服务Bindings，所有服务都应该放在这里
Bindings servicesBindings() => BindingsBuilder(() {
      Get.put(TimeService());
      Get.put(SettingsService());
      Get.put(UserService());
      Get.put(PersistentDataService());
      Get.put(ImageService());
      Get.put(ForumListService());
      Get.put(BlacklistService());
      Get.put(PostHistoryService());
      Get.put(PostDraftListService());
      Get.put(EmoticonListService());
      Get.put(XdnmbClientService());
    });
