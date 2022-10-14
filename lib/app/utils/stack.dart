import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/post_list.dart';

class _ControllerData {
  final int key;

  final List<PostListController> controllers;

  const _ControllerData({required this.key, required this.controllers});
}

abstract class ControllerStack {
  static final List<_ControllerData> _cache = [
    _ControllerData(key: _latestKey, controllers: [])
  ];

  static int index = 0;

  static final RxInt length = 1.obs;

  static int _latestKey = 0;

  static PostListController getController([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack.index].controllers.last;

  static PostListController getFirstController([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack.index].controllers.first;

  static int getKeyId([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack.index].key;

  static int controllersCount([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack.index].controllers.length;

  static void pushController(PostListController controller, [int? index]) {
    index = index ?? ControllerStack.index;
    if (index >= 0 && index < _cache.length) {
      _cache[index].controllers.add(controller);
    } else {
      debugPrint('pushController(): index out of range');
    }
  }

  static void popController([int? index]) {
    index = index ?? ControllerStack.index;
    if (index >= 0 && index < _cache.length) {
      final controller = _cache[index].controllers.removeLast();
      controller.dispose();
    } else {
      debugPrint('popController(): index out of range');
    }
  }

  static void addNewController(PostListController controller) {
    _latestKey += 1;
    _cache.add(_ControllerData(key: _latestKey, controllers: [controller]));
    length.value = _cache.length;
  }

  static void removeControllersAt(int index) {
    if (_cache.length <= 1) {
      debugPrint('removeControllerAt(): cache length is less than 2');
    } else if (index >= 0 && index < _cache.length) {
      final data = _cache.removeAt(index);
      for (final contorller in data.controllers) {
        contorller.dispose();
      }

      length.value = _cache.length;
      if (ControllerStack.index > index) {
        ControllerStack.index -= 1;
      } else if (ControllerStack.index == index) {
        ControllerStack.index = min(ControllerStack.index, _cache.length - 1);
      }
    } else {
      debugPrint('removeControllersAt(): index out of range');
    }
  }

  static void replaceLastController(PostListController controller,
      [int? index]) {
    popController(index);
    pushController(controller, index);
  }
}
