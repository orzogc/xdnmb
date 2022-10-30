import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/post_list.dart';
import 'notify.dart';

class _ControllerData {
  final int key;

  final List<PostListController> controllers;

  const _ControllerData({required this.key, required this.controllers});
}

abstract class ControllerStack {
  static final List<_ControllerData> _cache = [
    _ControllerData(key: _latestKey, controllers: [])
  ];

  static int _index = 0;

  static final RxInt _length = 1.obs;

  static int _latestKey = 0;

  /// 用来提醒[ControllerStack]的变化
  static final Notifier notifier = Notifier();

  static int get index => _index;

  static set index(int index) {
    _index = index;
    notifier.notify();
  }

  static int get length => _length.value;

  static PostListController getController([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack._index].controllers.last;

  static PostListController getFirstController([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack._index].controllers.first;

  static int getKeyId([int? index]) =>
      ControllerStack._cache[index ?? ControllerStack._index].key;

  static int controllersCount([int? index]) => ControllerStack
      ._cache[index ?? ControllerStack._index].controllers.length;

  static void pushController(PostListController controller, [int? index]) {
    index = index ?? ControllerStack._index;
    if (index >= 0 && index < _cache.length) {
      _cache[index].controllers.add(controller);

      notifier.notify();
    } else {
      debugPrint('pushController(): index out of range');
    }
  }

  static void popController([int? index]) {
    index = index ?? ControllerStack._index;
    if (index >= 0 && index < _cache.length) {
      final controller = _cache[index].controllers.removeLast();
      controller.dispose();

      notifier.notify();
    } else {
      debugPrint('popController(): index out of range');
    }
  }

  static void addNewController(PostListController controller) {
    _latestKey += 1;
    _cache.add(_ControllerData(key: _latestKey, controllers: [controller]));
    _length.value = _cache.length;

    notifier.notify();
  }

  static void removeControllersAt(int index) {
    if (_cache.length <= 1) {
      debugPrint('removeControllersAt(): cache length is less than 2');
    } else if (index >= 0 && index < _cache.length) {
      final data = _cache.removeAt(index);
      for (final contorller in data.controllers) {
        contorller.dispose();
      }

      _length.value = _cache.length;
      if (ControllerStack._index > index) {
        ControllerStack._index -= 1;
      } else if (ControllerStack._index == index) {
        ControllerStack._index = min(ControllerStack._index, _cache.length - 1);
      }

      notifier.notify();
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
