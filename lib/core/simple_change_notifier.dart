import 'dart:async';
import 'package:flutter/material.dart';

/// Синтаксический сахар над ChangeNotifier
// Используем implements, чтобы SimpleChangeNotifier стал ChangeNotifier, и при этом остался миксином
mixin SimpleChangeNotifier implements ChangeNotifier {
  // Копируем стандартную реализацию или добавляем свою
  final List<VoidCallback> _listeners = [];

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void dispose() => _listeners.clear();

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  FutureOr<void> notify(FutureOr<void> Function() lambda) async {
    await lambda();
    notifyListeners();
  }
}
