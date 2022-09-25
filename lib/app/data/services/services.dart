import 'package:get/get.dart';

import 'drafts.dart';
import 'emoticons.dart';
import 'forum.dart';
import 'history.dart';
import 'image.dart';
import 'persistent.dart';
import 'settings.dart';
import 'time.dart';
import 'user.dart';
import 'xdnmb_client.dart';

Bindings servicesBindings() => BindingsBuilder(() {
      Get.put(TimeService());
      Get.put(SettingsService());
      Get.put(UserService());
      Get.put(PersistentDataService());
      Get.put(ImageService());
      Get.put(ForumListService());
      Get.put(PostHistoryService());
      Get.put(PostDraftsService());
      Get.put(EmoticonsService());
      Get.put(XdnmbClientService());
    });
