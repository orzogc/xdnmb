import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef NotifyBuilder = AnimatedBuilder;

class Notifier extends ChangeNotifier {
  Notifier();

  void notify() => notifyListeners();
}

class ListenableNotifier extends ChangeNotifier
    implements ValueListenable<bool> {
  bool _value;

  @override
  bool get value => _value;

  ListenableNotifier([bool value = false]) : _value = value;

  void notify() => notifyListeners();

  void trigger() {
    _value = !_value;
    notify();
  }
}
