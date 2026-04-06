import 'package:coldcall/core/err.dart';
import 'package:flutter/material.dart';
import 'error_presenters.dart';

/// Синтаксический сахар над FutureBuilder
class SimpleFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T? data) builder;
  final Widget? placeholder;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const SimpleFutureBuilder({super.key, required this.future, required this.builder, this.placeholder, this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == .waiting) {
          return Material(child: placeholder ?? Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return (errorBuilder != null)
              ? errorBuilder!(snapshot.error!, snapshot.stackTrace)
              : ErrorPresenter(userError: UserError.from(snapshot.error!, snapshot.stackTrace));
        } else {
          return builder(context, (snapshot.hasData) ? snapshot.requireData : null);
        }
      },
    );
  }
}

/// Синтаксический сахар над ListenableBuilder, который прокидывает listenable типизированным параметром в builder
class SimpleListenableBuilder<T extends Listenable> extends StatelessWidget {
  final T listenable;
  final Widget? staticChild; // Добавляем поддержку статичного потомка
  final Widget Function(BuildContext context, T listenable, Widget? child) builder;

  const SimpleListenableBuilder({super.key, required this.listenable, required this.builder, this.staticChild});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      child: staticChild,
      builder: (context, staticChild) {
        return builder(context, listenable, staticChild);
      },
    );
  }
}

/// FutureBuilder + ListenableBuilder - типичный сценарий инициализации + обновления экрана при использовании ChangeNotifier mixin
class SimpleFutureListenableBuilder<T1, T2 extends Listenable> extends StatelessWidget {
  final Future<T1> initFuture;
  final T2 listenable;
  final Widget Function(BuildContext context, T1? initResult, T2 listenable) builder;
  final Widget? placeholder;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const SimpleFutureListenableBuilder({
    super.key,
    required this.initFuture,
    required this.listenable,
    required this.builder,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleFutureBuilder<T1>(
      future: initFuture,
      builder: (context, initResult) {
        return SimpleListenableBuilder<T2>(
          listenable: listenable,
          builder: (context, listenagle, _) {
            return builder(context, initResult, listenagle);
          },
        );
      },
    );
  }
}
