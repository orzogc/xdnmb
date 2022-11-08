import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../modules/post_list.dart';
import '../../utils/notify.dart';
import '../../widgets/forum.dart';
import '../models/controller.dart';
import '../models/hive.dart';
import 'persistent.dart';
import 'settings.dart';

const int _int16Max = 65535;

int _hiveKey(int keyId, int index) {
  assert(keyId <= _int16Max && index <= _int16Max);

  return keyId << 16 | index;
}

extension _IntExtension on int {
  int get _keyId => this >>> 16;

  int get _index => this & _int16Max;
}

class ControllerData {
  final int key;

  final PostListController controller;

  ControllerData(this.key, this.controller) {
    controller.save = _save;
  }

  void _save() => ControllerStacksService.to._controllerBox
      .put(key, PostListControllerData.fromController(controller));

  void _dispose() => controller.dispose();
}

class _StackData {
  final int keyId;

  final List<ControllerData> controllers;

  /// 用来提醒[_StackData]的变化
  final Notifier _notifier = Notifier();

  void _notify() => _notifier.notify();

  void _dispose() => _notifier.dispose();

  _StackData(this.keyId, this.controllers);
}

class ControllerStacksService extends GetxService {
  static ControllerStacksService get to => Get.find<ControllerStacksService>();

  late final Box<PostListControllerData> _controllerBox;

  final List<_StackData> _stacks = [];

  int _currentStackIndex = 0;

  final RxInt _stackListLength = 0.obs;

  int _latestKeyId = -1;

  /// 用来提醒[ControllerStacksService]的变化
  final Notifier notifier = Notifier();

  final RxBool isReady = false.obs;

  int get index => _currentStackIndex;

  set index(int index) {
    if (index >= 0 && index < _stacks.length) {
      _currentStackIndex = index;
      PersistentDataService.to.controllerStackListIndex = index;
      _notify();
    } else {
      debugPrint('index out of bounds');
    }
  }

  int get length => _stackListLength.value;

  void _notify() => notifier.notify();

  PostListController getController([int? index]) =>
      _stacks[index ?? this.index].controllers.last.controller;

  PostListController getFirstController([int? index]) =>
      _stacks[index ?? this.index].controllers.first.controller;

  int getKeyId([int? index]) => _stacks[index ?? this.index].keyId;

  int controllersCount([int? index]) =>
      _stacks[index ?? this.index].controllers.length;

  Notifier getStackNotifier([int? index]) =>
      _stacks[index ?? this.index]._notifier;

  List<ControllerData> getControllers([int? index]) =>
      _stacks[index ?? this.index].controllers;

  void pushController(PostListController controller, [int? index]) {
    index = index ?? this.index;
    if (index >= 0 && index < _stacks.length) {
      final controllers = _stacks[index].controllers;
      final controllerData = ControllerData(
          _hiveKey(_stacks[index].keyId, controllers.length), controller);
      controllers.add(controllerData);

      _controllerBox.put(controllerData.key,
          PostListControllerData.fromController(controller));
      _stacks[index]._notify();
      _notify();
    } else {
      debugPrint('pushController(): index out of bounds');
    }
  }

  void popController([int? index]) {
    index = index ?? this.index;
    if (index >= 0 && index < _stacks.length) {
      final controllers = _stacks[index].controllers;
      if (controllers.isNotEmpty) {
        final controllerData = controllers.removeLast();
        controllerData._dispose();
        _controllerBox.delete(controllerData.key);

        _stacks[index]._notify();
        _notify();
      } else {
        debugPrint('popController(): controllers list is empty');
      }
    } else {
      debugPrint('popController(): index out of bounds');
    }
  }

  void addNewStack(PostListController controller) {
    _latestKeyId++;
    final controllerData =
        ControllerData(_hiveKey(_latestKeyId, 0), controller);
    _stacks.add(_StackData(_latestKeyId, [controllerData]));
    _stackListLength.value = _stacks.length;

    _controllerBox.put(
        controllerData.key, PostListControllerData.fromController(controller));
    _notify();
  }

  void removeStackAt(int index) {
    if (_stacks.length <= 1) {
      debugPrint('removeStackAt(): stacks\' length is less than 2');
    } else if (index >= 0 && index < _stacks.length) {
      final stack = _stacks.removeAt(index);

      _stackListLength.value = _stacks.length;
      if (this.index > index) {
        this.index -= 1;
      } else if (this.index == index) {
        this.index = min(this.index, _stacks.length - 1);
      }

      for (final contorllerData in stack.controllers) {
        contorllerData._dispose();
        _controllerBox.delete(contorllerData.key);
      }
      stack._dispose();

      _notify();
    } else {
      debugPrint('removeStackAt(): index out of bounds');
    }
  }

  void replaceLastController(PostListController controller, [int? index]) {
    popController(index);
    pushController(controller, index);
  }

  List<int> getControllerKeys() {
    final List<int> list = [];

    for (final stack in _stacks) {
      for (final controller in stack.controllers) {
        list.add(controller.key);
      }
    }

    return list;
  }

  Future<void> _buildStacks() async {
    final settings = SettingsService.to;

    if (settings.isRestoreTabs && _controllerBox.isNotEmpty) {
      final map = _controllerBox.toMap();
      await _controllerBox.clear();
      final List<int> keys = List.from(map.keys)..sort();
      final Map<int, List<int>> keysMap = {};

      for (final key in keys) {
        final index = key._keyId;
        if (keysMap.containsKey(index)) {
          keysMap[index]!.add(key._index);
        } else {
          keysMap[index] = [key._index];
        }
      }

      for (final entry in keysMap.entries) {
        bool isAdded = false;
        for (final key in entry.value) {
          final controller = map[_hiveKey(entry.key, key)];
          if (controller != null) {
            if (!isAdded) {
              addNewStack(
                  controller.toController(SettingsService.isRestoreForumPage));
              isAdded = true;
            } else {
              pushController(
                  controller.toController(SettingsService.isRestoreForumPage),
                  _stacks.length - 1);
            }
          } else {
            debugPrint('控制器key不存在：$entry');
          }
        }
      }

      _currentStackIndex = PersistentDataService.to.controllerStackListIndex;
    } else {
      await _controllerBox.clear();
      addNewStack(
          ForumTypeController.fromForumData(forum: settings.initialForum));
    }
  }

  @override
  void onInit() async {
    super.onInit();

    _controllerBox =
        await Hive.openBox<PostListControllerData>(HiveBoxName.controllers);

    final data = PersistentDataService.to;
    final settings = SettingsService.to;

    while (!data.isReady.value || !settings.isReady.value) {
      debugPrint('等待读取恢复控制器栈相关数据');

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (settings.isRestoreTabs) {
      index = data.controllerStackListIndex;
    }

    await _buildStacks();

    isReady.value = true;

    debugPrint('读取控制器栈成功');
  }

  @override
  void onClose() async {
    await _controllerBox.close();
    notifier.dispose();
    isReady.value = false;

    super.onClose();
  }
}
