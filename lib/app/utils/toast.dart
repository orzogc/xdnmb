import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../data/services/persistent.dart';

Future<void> showToast(String message) {
  debugPrint(message);

  return EasyLoading.showToast(message,
      toastPosition: PersistentDataService.to.isKeyboardVisible
          ? EasyLoadingToastPosition.top
          : EasyLoadingToastPosition.bottom);
}
