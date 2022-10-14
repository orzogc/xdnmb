import 'package:flutter/material.dart';

typedef NotifyBuilder = AnimatedBuilder;

class Notifier extends ChangeNotifier {
  Notifier();

  void notify() => notifyListeners();
}
