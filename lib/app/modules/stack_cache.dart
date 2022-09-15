import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_widget_cache.dart';

class _ControllerData {
  final int key;

  final List<GetLifeCycleBase> controllers;

  const _ControllerData({required this.key, required this.controllers});
}

abstract class StackCacheView<S extends GetLifeCycleBase>
    extends GetWidgetCache {
  static final List<_ControllerData> _cache = [
    const _ControllerData(key: 0, controllers: [])
  ];

  static int index = 0;

  static final RxInt length = 1.obs;

  static int _latestKey = 0;

  @protected
  final String? tag = null;

  S get _controller => StackCacheView._cache[index].controllers.last as S;

  const StackCacheView({super.key});

  static GetLifeCycleBase getController([int? index]) =>
      StackCacheView._cache[index ?? StackCacheView.index].controllers.last;

  static GetLifeCycleBase getFirstController([int? index]) =>
      StackCacheView._cache[index ?? StackCacheView.index].controllers.first;

  static int getKeyId([int? index]) =>
      StackCacheView._cache[index ?? StackCacheView.index].key;

  static int controllersCount([int? index]) =>
      StackCacheView._cache[index ?? StackCacheView.index].controllers.length;

  static void pushController(GetLifeCycleBase s, [int? index]) {
    index = index ?? StackCacheView.index;
    if (index >= 0 && index < _cache.length) {
      _cache[index].controllers.add(s);
    } else {
      debugPrint('pushController(): index out of range');
    }
  }

  static void popController([int? index]) {
    index = index ?? StackCacheView.index;
    if (index >= 0 && index < _cache.length) {
      _cache[index].controllers.removeLast();
    } else {
      debugPrint('popController(): index out of range');
    }
  }

  static void addController(GetLifeCycleBase s) {
    _latestKey += 1;
    _cache.add(_ControllerData(key: _latestKey, controllers: [s]));
    length.value = _cache.length;
  }

  static List<GetLifeCycleBase>? removeControllerAt(int index) {
    if (_cache.length <= 1) {
      debugPrint('removeControllerAt(): cache length is less than 2');
    } else if (index >= 0 && index < _cache.length) {
      final s = _cache.removeAt(index);
      length.value = _cache.length;
      if (StackCacheView.index > index) {
        StackCacheView.index -= 1;
      } else if (StackCacheView.index == index) {
        StackCacheView.index = min(StackCacheView.index, _cache.length - 1);
      }
      return s.controllers;
    } else {
      debugPrint('removeControllerAt(): index out of range');
    }

    return null;
  }

  @protected
  Widget build(BuildContext context);

  @override
  WidgetCache<GetWidgetCache> createWidgetCache() => _StackCache<S>();
}

class _StackCache<S extends GetLifeCycleBase>
    extends WidgetCache<StackCacheView<S>> {
  bool _isCreator = false;

  @override
  void onInit() {
    super.onInit();

    final info = GetInstance().getInstanceInfo<S>(tag: widget!.tag);
    _isCreator = info.isPrepared && info.isCreate;

    final controller = info.isRegistered ? Get.find<S>(tag: widget!.tag) : null;
    final data = StackCacheView._cache[StackCacheView.index];
    if (data.controllers.isEmpty) {
      StackCacheView._cache[StackCacheView.index] =
          _ControllerData(key: data.key, controllers: [controller!]);
    } else {
      data.controllers.add(controller!);
      StackCacheView._cache[StackCacheView.index] =
          _ControllerData(key: data.key, controllers: data.controllers);
    }
  }

  @override
  void onClose() {
    if (_isCreator) {
      Get.asap(() {
        widget!._controller.onDelete();
        Get.log('"${widget!._controller.runtimeType}" onClose() called');
        Get.log('"${widget!._controller.runtimeType}" deleted from memory');
        StackCacheView._cache[StackCacheView.index].controllers.removeLast();
      });
    }

    super.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return widget!.build(context);
  }
}
