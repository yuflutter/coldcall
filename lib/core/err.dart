import 'dart:async';
import 'package:coldcall/core/di.dart';
import 'package:coldcall/core/log.dart';

/// Преобразует ошибку в вид, пригодный для презентера или отправки в лог.
class UserError {
  final String short;
  final String? long;

  UserError._({required this.short, this.long});

  factory UserError.from(Object e, StackTrace? s, {String? msg}) {
    final short = (msg?.isNotEmpty == true) ? msg! : e.toString();

    final long = <String>[];
    if (msg?.isNotEmpty == true) long.add(msg!);
    long.add(e.toString());
    if (s != null) long.add(s.toString());

    return UserError._(short: short, long: long.join('\n'));
  }
}

/// Глобальный менеджер ошибок. Пушит ошибки на главный экран.
class Err {
  late final _log = Log('$runtimeType');
  final _errController = StreamController<UserError>();
  late final errStream = _errController.stream;

  void addError(Object e, StackTrace? s, {String? msg}) {
    _log.err(e, s, msg: msg);
    _errController.add(UserError.from(e, s, msg: msg));
  }

  static void add(Object e, StackTrace? s, {String? msg}) => di<Err>().addError(e, s, msg: msg);
}
