import 'dart:developer' as dev;
import 'package:coldcall/core/err.dart';

/// Глобальный логгер. TODO: Добавить нормальную реализацию.
class Log {
  final String name;
  final void Function(Object)? on;

  Log(this.name, {this.on});

  void err(Object e, StackTrace? s, {String? msg}) {
    final error = UserError.from(e, s, msg: msg);
    dev.log(error.short, name: name, error: e, stackTrace: s);
    on?.call(error.toString());
  }

  void inf(dynamic i) {
    final m = i.toString();
    dev.log(m, name: name);
    on?.call(m);
  }

  void war(dynamic i, {StackTrace? stack}) {
    final m = i.toString();
    dev.log(m, name: name, level: 1, stackTrace: stack);
    on?.call(m);
  }

  static void deb(dynamic i) => Log('LOGDEB').war(i);
}
