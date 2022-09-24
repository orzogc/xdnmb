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
      _cache[index].controllers.removeLast();
    } else {
      debugPrint('popController(): index out of range');
    }
  }

  static void addController(PostListController controller) {
    _latestKey += 1;
    _cache.add(_ControllerData(key: _latestKey, controllers: [controller]));
    length.value = _cache.length;
  }

  static List<PostListController>? removeControllerAt(int index) {
    if (_cache.length <= 1) {
      debugPrint('removeControllerAt(): cache length is less than 2');
    } else if (index >= 0 && index < _cache.length) {
      final data = _cache.removeAt(index);
      length.value = _cache.length;
      if (ControllerStack.index > index) {
        ControllerStack.index -= 1;
      } else if (ControllerStack.index == index) {
        ControllerStack.index = min(ControllerStack.index, _cache.length - 1);
      }
      return data.controllers;
    } else {
      debugPrint('removeControllerAt(): index out of range');
    }

    return null;
  }
}
